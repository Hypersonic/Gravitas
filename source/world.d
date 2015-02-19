module gravitas.world;

import std.math;
import std.range;
import std.parallelism;

import core.simd;

struct World {
    static const float G = 2000f;
    static const int n_ents = 1 << 10;
    int last_ent = 0;
    float[n_ents] xs;
    float[n_ents] ys;
    float[n_ents] vxs;
    float[n_ents] vys;
    float[n_ents] axs;
    float[n_ents] ays;
    float[n_ents] masses;

    void step(float timestep = 1.0) {
        // Step everything
        foreach (i; iota(0, last_ent).parallel) {
            axs[i] = 0;
            ays[i] = 0;
            foreach (o; 0 .. last_ent) {
                auto dx = xs[o] - xs[i];
                auto dy = ys[o] - ys[i];
                auto len = sqrt(dx * dx + dy * dy);
                if (len != 0) {
                    auto dirx = dx / len;
                    auto diry = dy / len;
                    axs[i] += dirx * G * (masses[o]) / (len * len);
                    ays[i] += diry * G * (masses[o]) / (len * len);
                }
            }
            vxs[i] += axs[i] * timestep;
            vys[i] += ays[i] * timestep;
            xs[i] += vxs[i] * timestep;
            ys[i] += vys[i] * timestep;
        }
    }

    void push_ent(
            float x, float y,
            float vx, float vy,
            float ax, float ay,
            float mass) {
        this.xs[last_ent] = x;
        this.ys[last_ent] = y;
        this.vxs[last_ent] = vx;
        this.vys[last_ent] = vy;
        this.axs[last_ent] = ax;
        this.ays[last_ent] = ay;
        this.masses[last_ent] = mass;
        ++last_ent;
    }
}
