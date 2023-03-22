import std.stdio;
import bindbc.sdl;
import game;
import text;
import types;
import video;
import textScreen;
import titleScreen;

enum AppState {
	TitleScreen,
	InGame
}

class App {
	bool       running = true;
	size_t     ticks;
	TextScreen screen;
	AppState   state;

	// screens
	TitleScreen titleScreen;

	this() {
		VideoComponents.Instance().Init("The Genesis Story");
		TextComponents.Instance();
		auto game = Game.Instance();

		titleScreen = new TitleScreen();

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
		auto game = Game.Instance();
	
		++ ticks;
	
		SDL_Event e;

		while (SDL_PollEvent(&e)) {
			switch (e.type) {
				case SDL_KEYDOWN: {
					auto key = e.key.keysym.scancode;
					switch (state) {
						case AppState.TitleScreen: {
							titleScreen.HandleKeyPress(key);
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
			case AppState.InGame: {
				game.HandleInput(keyState);
				game.Render();
				break;
			}
			default: assert(0);
		}

		screen.Render();

		SDL_RenderPresent(VideoComponents.Instance().renderer);
	}
}

void main() {
	auto app = App.Instance();

	while (app.running) {
		app.Update();
	}
}
