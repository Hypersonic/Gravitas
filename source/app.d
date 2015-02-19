import std.stdio;
import std.typecons;
import std.conv;
import std.random;

import core.simd;

import gfm.sdl2;

import gravitas.world;

void main() {
    int width = 1000;
    int height = 1000;

    // load dynamic libraries
    auto sdl2 = scoped!SDL2(null);

    // create an OpenGL-enabled SDL window
    auto window = scoped!SDL2Window(sdl2, 
                                    SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED,
                                    width, height,
                                    SDL_WINDOW_BORDERLESS);

    auto renderer = scoped!SDL2Renderer(window);

    bool running = true;
    World world;
    foreach (i; 0 .. 10) {
        world.push_ent(uniform(0, width), uniform(0, height), 0, 0, 0, 0, uniform(1, 10));
    }
    while (running) {
        sdl2.processEvents();

        // Draw accelerations
        renderer.setColor(128, 0, 0);
        foreach (i; 0 .. world.last_ent) {
            auto x = world.xs[i] + world.vxs[i] + world.axs[i];
            auto y = world.ys[i] + world.vys[i] + world.ays[i];
            if (0 < x && x < width &&
                    0 < y && y < height) {
                renderer.drawLine(
                        (world.xs[i] + world.vxs[i]).to!int,
                        (world.ys[i] + world.vys[i]).to!int,
                        x.to!int, y.to!int);
            }
        }

        // Draw velocities
        renderer.setColor(0, 0, 128);
        foreach (i; 0 .. world.last_ent) {
            auto x = world.xs[i] + world.vxs[i];
            auto y = world.ys[i] + world.vys[i];
            if (0 < x && x < width &&
                    0 < y && y < height) {
                renderer.drawLine(
                        world.xs[i].to!int,
                        world.ys[i].to!int,
                        x.to!int, y.to!int);
            }
        }

        // Draw positions
        renderer.setColor(255, 255, 255);
        foreach (i; 0 .. world.last_ent) {
            auto x = world.xs[i];
            auto y = world.ys[i];
            if (0 < x && x < width &&
                0 < y && y < height) {
                renderer.drawPoint(x.to!int, y.to!int);
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
    }
}
