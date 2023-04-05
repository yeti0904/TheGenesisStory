import std.stdio;
import std.algorithm;
import std.datetime.stopwatch;
import core.thread;
import bindbc.sdl;
import game;
import text;
import types;
import video;
import textScreen;
import titleScreen;
import worldOptions;

enum AppState {
	TitleScreen,
	WorldOptions,
	InGame
}

class App {
	bool       running = true;
	size_t     ticks;
	TextScreen screen;
	AppState   state;
	float      fps;
	string     appVersion = "Beta 1.1.2";

	// screens
	TitleScreen      titleScreen;
	WorldOptionsMenu worldOptions;

	this() {
		VideoComponents.Instance().Init("The Genesis Story");
		TextComponents.Instance();
		auto game = Game.Instance();

		titleScreen  = new TitleScreen();
		worldOptions = new WorldOptionsMenu();

		screen = new TextScreen();

		screen.SetSize(Vec2!size_t(140, 40));
	}

	static App Instance() {
		static App instance;

		if (!instance) {
			instance = new App();
		}

		return instance;
	}

	void Update() {
		auto stopwatch = StopWatch(AutoStart.yes);
		auto game      = Game.Instance();
	
		++ ticks;

		if (state == AppState.InGame) {
			game.Update();
		}
	
		SDL_Event e;

		while (SDL_PollEvent(&e)) {
			switch (e.type) {
				case SDL_KEYDOWN: {
					auto key = e.key.keysym.scancode;

					if (key == SDL_SCANCODE_F12) {
						writeln("DEBUG INFO");
						writefln("FPS: %g", fps);
						writefln("Game camera: %s", game.camera);
					}
					
					switch (state) {
						case AppState.TitleScreen: {
							titleScreen.HandleKeyPress(key);
							break;
						}
						case AppState.WorldOptions: {
							worldOptions.HandleKeyPress(key);
							break;
						}
						case AppState.InGame: {
							game.HandleKeyPress(key);
							break;
						}
						default: assert(0);
					}
					break;
				}
				case SDL_QUIT: {
					running = false;
					break;
				}
				default: break;
			}
		}

		auto keyState = SDL_GetKeyboardState(null);

		switch (state) {
			case AppState.TitleScreen: {
				titleScreen.Render();
				break;
			}
			case AppState.WorldOptions: {
				worldOptions.Render();
				break;
			}
			case AppState.InGame: {
				game.HandleInput(keyState);
				game.Render();
				break;
			}
			default: assert(0);
		}

		screen.Render();

		SDL_RenderPresent(VideoComponents.Instance().renderer);

		stopwatch.stop();

		int deltaTime = cast(int) stopwatch.peek.total!"msecs"();
		fps = 1000 / deltaTime;
		
		Thread.sleep(dur!"msecs"(max((1000 / 60) - deltaTime, 0)));
	}
}

void main() {
	auto app = App.Instance();

	while (app.running) {
		app.Update();
	}
}
