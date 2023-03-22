import std.file;
import std.stdio;
import std.string;
import core.stdc.stdlib;
import bindbc.sdl;

SDL_Color HexToColour(int hexValue) {
	return SDL_Color(
		(hexValue >> 16) & 0xFF,
		(hexValue >> 8) & 0xFF,
		hexValue & 0xFF,
		255
	);
}

class VideoComponents {
	SDL_Window*   window;
	SDL_Renderer* renderer;

	this() {
		
	}

	~this() {
		SDL_DestroyWindow(window);
		SDL_DestroyRenderer(renderer);
		SDL_Quit();
	}

	static VideoComponents Instance() {
		static VideoComponents ret;

		if (!ret) {
			ret = new VideoComponents();
		}

		return ret;
	}

	void Init(string windowName) {
		// load SDL
		SDLSupport support = loadSDL();
		if (support != sdlSupport) {
			stderr.writeln("Failed to load SDL");
			exit(1);
		}
		version (Windows) {
			loadSDL(dirName(thisExePath()) ~ "/sdl2.dll");
		}

		// init
		if (SDL_Init(SDL_INIT_VIDEO) < 0) {
			stderr.writefln("Failed to init SDL: %s", fromStringz(SDL_GetError()));
			exit(1);
		}

		// window
		window = SDL_CreateWindow(
			cast(char*) toStringz(windowName),
			SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
			320, 384, 0
		);
		if (window is null) {
			stderr.writefln("Failed to create window: %s", fromStringz(SDL_GetError()));
			exit(1);
		}

		renderer = SDL_CreateRenderer(
			window, -1, SDL_RENDERER_ACCELERATED
		);
		if (renderer is null) {
			stderr.writefln("Failed to create renderer: %s", fromStringz(SDL_GetError()));
			exit(1);
		}
	}
}
