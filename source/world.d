module gravitas.world;

import std.math;
import std.range;
import std.parallelism;

import core.simd;

struct World {
    static const float G = 2000f;
    static const int n_ents = 1 << 10;
    static const int veclen = 4;
    // We need to have this be an evenly divisible amount
    static assert (n_ents % veclen == 0, "world.n_ents is not divisible by world.veclen");
    alias vecType = float4;
    int last_ent = 0;
    int last_ent_sub = 0;
    vecType[n_ents / veclen] xs;
    vecType[n_ents / veclen] ys;
    vecType[n_ents / veclen] zs;
    vecType[n_ents / veclen] vxs;
    vecType[n_ents / veclen] vys;
    vecType[n_ents / veclen] vzs;
    vecType[n_ents / veclen] axs;
    vecType[n_ents / veclen] ays;
    vecType[n_ents / veclen] azs;
    vecType[n_ents / veclen] masses;

    void step(float timestep = 1.0) {
        // Step everything
        foreach (i; iota(0, last_ent + 1).parallel) {
            axs[i] = 0;
            ays[i] = 0;
            azs[i] = 0;
            foreach (o; 0 .. last_ent + 1) {
                foreach (j; iota(0, veclen)) {
                    foreach(k; iota(0, veclen)) {
                        if (i == o && j == k) continue; // skip when we're looking at the same thing
                        import std.stdio;
                        auto dx = xs[o].array[k] - xs[i].array[j];
                        auto dy = ys[o].array[k] - ys[i].array[j];
                        auto dz = zs[o].array[k] - zs[i].array[j];

                        // compute lengths
                        auto len = 0f;
                        auto sqsum = dx * dx + dy * dy + dz * dz;
                        len = sqrt(sqsum);

                        auto maxdist = masses[o].array[k] / 8;
                        if (len < maxdist) {
                            bool firstbigger = masses[i].array[j] > masses[o].array[k];

                            auto bigger_f = firstbigger ? i : o;
                            auto bigger_s = firstbigger ? j : k;

                            auto smaller_f = firstbigger ? o : i;
                            auto smaller_s = firstbigger ? k : j;

                            // Combine velocities
                            auto mass_ratio = masses[smaller_f].array[smaller_s] / masses[bigger_f].array[bigger_s];
                            vxs[bigger_f].array[bigger_s] += vxs[smaller_f].array[smaller_s] * mass_ratio;
                            vys[bigger_f].array[bigger_s] += vys[smaller_f].array[smaller_s] * mass_ratio;
                            vzs[bigger_f].array[bigger_s] += vzs[smaller_f].array[smaller_s] * mass_ratio;

                            // Move mass from smaller to bigger
                            masses[bigger_f].array[bigger_s] += masses[smaller_f].array[smaller_s];
                            masses[smaller_f].array[smaller_s] = 0;
                            
                            // Get rid of smaller
                            xs[smaller_f].array[smaller_s] = -100000000;
                            ys[smaller_f].array[smaller_s] = -100000000;
                            zs[smaller_f].array[smaller_s] = -100000000;
                            vxs[smaller_f].array[smaller_s] = 0;
                            vys[smaller_f].array[smaller_s] = 0;
                            vzs[smaller_f].array[smaller_s] = 0;
                            axs[smaller_f].array[smaller_s] = 0;
                            ays[smaller_f].array[smaller_s] = 0;
                            azs[smaller_f].array[smaller_s] = 0;
                        } else if (len != 0) {
                            auto dirx = dx / len;
                            auto diry = dy / len;
                            auto dirz = dz / len;
                            axs[i].array[j] += dirx * G * (masses[o].array[k]) / (len * len);
                            ays[i].array[j] += diry * G * (masses[o].array[k]) / (len * len);
                            azs[i].array[j] += dirz * G * (masses[o].array[k]) / (len * len);
                        }
                    }
                }
            }
            vecType ts;
            foreach (k; 0 .. veclen) {
                ts.array[k] = timestep;
            }
            vxs[i] += axs[i] * ts;
            vys[i] += ays[i] * ts;
            vzs[i] += azs[i] * ts;
            xs[i] += vxs[i] * ts;
            ys[i] += vys[i] * ts;
            zs[i] += vzs[i] * ts;
        }
    }

    void push_ent(
            float x, float y, float z,
            float vx, float vy, float vz,
            float ax, float ay, float az,
            float mass) {
        this.xs[last_ent].array[last_ent_sub] = x;
        this.ys[last_ent].array[last_ent_sub] = y;
        this.zs[last_ent].array[last_ent_sub] = z;
        this.vxs[last_ent].array[last_ent_sub] = vx;
        this.vys[last_ent].array[last_ent_sub] = vy;
        this.vzs[last_ent].array[last_ent_sub] = vz;
        this.axs[last_ent].array[last_ent_sub] = ax;
        this.ays[last_ent].array[last_ent_sub] = ay;
        this.azs[last_ent].array[last_ent_sub] = az;
        this.masses[last_ent].array[last_ent_sub] = mass;
        ++last_ent_sub;
        if (last_ent_sub == veclen) {
            last_ent_sub = 0;
            ++last_ent;
            this.xs[last_ent] = 0;
            this.ys[last_ent] = 0;
            this.zs[last_ent] = 0;
            this.vxs[last_ent] = 0;
            this.vys[last_ent] = 0;
            this.vzs[last_ent] = 0;
            this.axs[last_ent] = 0;
            this.ays[last_ent] = 0;
            this.azs[last_ent] = 0;
            this.masses[last_ent] = 0;
        }
    }
}
