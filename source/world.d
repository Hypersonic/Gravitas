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
    vecType[n_ents / veclen] vxs;
    vecType[n_ents / veclen] vys;
    vecType[n_ents / veclen] axs;
    vecType[n_ents / veclen] ays;
    vecType[n_ents / veclen] masses;

    void step(float timestep = 1.0) {
        // Step everything
        foreach (i; iota(0, last_ent).parallel) {
            axs[i] = 0;
            ays[i] = 0;
            foreach (o; 0 .. last_ent) {
                if (i == o) continue; // skip when we're looking at the same thing
                auto dx = xs[o] - xs[i];
                auto dy = ys[o] - ys[i];

                // compute lengths
                vecType lens;
                auto sqsums = dx * dx + dy * dy;
                foreach (k; iota(0, veclen)) {
                    lens.array[k] = sqrt(sqsums.array[k]);
                }

                auto dirx = dx / lens;
                auto diry = dy / lens;
                axs[i] += dirx * G * (masses[o]) / (lens * lens);
                ays[i] += diry * G * (masses[o]) / (lens * lens);
            }
            vecType ts;
            foreach (k; 0 .. veclen) {
                ts.array[k] = timestep;
            }
            vxs[i] += axs[i] * ts;
            vys[i] += ays[i] * ts;
            xs[i] += vxs[i] * ts;
            ys[i] += vys[i] * ts;
        }
    }

    void push_ent(
            float x, float y,
            float vx, float vy,
            float ax, float ay,
            float mass) {
        this.xs[last_ent].array[last_ent_sub] = x;
        this.ys[last_ent].array[last_ent_sub] = y;
        this.vxs[last_ent].array[last_ent_sub] = vx;
        this.vys[last_ent].array[last_ent_sub] = vy;
        this.axs[last_ent].array[last_ent_sub] = ax;
        this.ays[last_ent].array[last_ent_sub] = ay;
        this.masses[last_ent].array[last_ent_sub] = mass;
        ++last_ent_sub;
        if (last_ent_sub == veclen) {
            last_ent_sub = 0;
            ++last_ent;
        }
    }
}
