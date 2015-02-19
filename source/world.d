module gravitas.world;

import std.math;
import std.range;
import std.parallelism;

import core.simd;

struct World {
    static const float G = 2000f;
    static const int n_ents = 1 << 10;
    static const int veclen = 4;
    int last_ent = 0;
    int last_ent_sub = 0;
    float4[n_ents / veclen] xs;
    float4[n_ents / veclen] ys;
    float4[n_ents / veclen] vxs;
    float4[n_ents / veclen] vys;
    float4[n_ents / veclen] axs;
    float4[n_ents / veclen] ays;
    float4[n_ents / veclen] masses;

    void step(float timestep = 1.0) {
        // Step everything
        foreach (i; iota(0, last_ent).parallel) {
            axs[i] = 0;
            ays[i] = 0;
            foreach (o; 0 .. last_ent) {
                auto dx = xs[o] - xs[i];
                auto dy = ys[o] - ys[i];
                foreach (k; 0 .. veclen) {
                    auto len = sqrt(dx.array[k] * dx.array[k] + dy.array[k] * dy.array[k]);
                    if (len != 0) {
                        auto dirx = dx.array[k] / len;
                        auto diry = dy.array[k] / len;
                        axs[i].array[k] += dirx * G * (masses[o].array[k]) / (len * len);
                        ays[i].array[k] += diry * G * (masses[o].array[k]) / (len * len);
                    }
                }
            }
            float4 ts;
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
