import std.stdio;
import std.typecons;
import std.conv;
import std.random;

import core.simd;

import gfm.sdl2;
import gfm.math;

import gravitas.world;

void main() {
    int width = 1000;
    int height = 1000;
    int depth = 1000;

    // load dynamic libraries
    auto sdl2 = scoped!SDL2(null);

    // create an OpenGL-enabled SDL window
    auto window = scoped!SDL2Window(sdl2, 
                                    SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED,
                                    width, height,
                                    SDL_WINDOW_BORDERLESS);

    auto renderer = scoped!SDL2Renderer(window);

    bool draw_vel = true;
    bool draw_acc = true;
    bool running = true;
    World world;
    foreach (i; 0 .. 256) {
        auto vx = uniform(-10, 10);
        auto vy = uniform(-10, 10);
        auto vz = uniform(-10, 10);
        world.push_ent(uniform(0, width), uniform(0, height), uniform(0, depth), vx, vy, vz, 0, 0, 0, uniform(1, 20));
    }
    while (running) {
        sdl2.processEvents();

        if (draw_acc) {
            // Draw accelerations
            renderer.setColor(128, 0, 0);
            foreach (i; 0 .. world.last_ent + 1) {
                foreach (k; 0 .. world.veclen) {
                    auto x = world.xs[i].array[k] + world.vxs[i].array[k] + world.axs[i].array[k];
                    auto y = world.ys[i].array[k] + world.vys[i].array[k] + world.ays[i].array[k];
                    if (0 < x && x < width &&
                            0 < y && y < height) {
                        renderer.drawLine(
                                (world.xs[i].array[k] + world.vxs[i].array[k]).to!int,
                                (world.ys[i].array[k] + world.vys[i].array[k]).to!int,
                                x.to!int, y.to!int);
                    }
                }
            }
        }

        if (draw_vel) {
            // Draw velocities
            renderer.setColor(0, 0, 128);
            foreach (i; 0 .. world.last_ent + 1) {
                foreach (k; 0 .. world.veclen) {
                    auto x = world.xs[i].array[k] + world.vxs[i].array[k];
                    auto y = world.ys[i].array[k] + world.vys[i].array[k];
                    if (0 < x && x < width &&
                            0 < y && y < height) {
                        renderer.drawLine(
                                world.xs[i].array[k].to!int,
                                world.ys[i].array[k].to!int,
                                x.to!int, y.to!int);
                    }
                }
            }
        }

        // Draw positions
        renderer.setColor(255, 255, 255);
        foreach (i; 0 .. world.last_ent + 1) {
            foreach (k; 0 .. world.veclen) {
                auto x = world.xs[i].array[k];
                auto y = world.ys[i].array[k];
                auto mass = world.masses[i].array[k] / 5;
                if (0 < x && x < width &&
                        0 < y && y < height) {
                    renderer.fillRect((x - mass/2).to!int, (y - mass/2).to!int, mass.to!int, mass.to!int);
                }
            }
        }
        world.step(.01);

        renderer.present();
        renderer.setColor(0, 0, 0, 0);
        renderer.clear();

        // Exit on escape
        if (sdl2.keyboard().isPressed(SDLK_ESCAPE)) {
            running = false;
        }
        // Hit a to toggle acceleration drawing
        if (sdl2.keyboard().isPressed(SDLK_a)) {
            draw_acc = !draw_acc;
        }
        // Hit v to toggle velocity drawing
        if (sdl2.keyboard().isPressed(SDLK_v)) {
            draw_vel = !draw_vel;
        }
    }
}
