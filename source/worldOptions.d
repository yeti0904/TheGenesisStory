import bindbc.sdl;
import app;
import game;
import video;
import types;
import textScreen;

class WorldOptionsMenu {
	size_t   selectedBelieverLevel;
	string[] believerLevels = [
		"None", "Very low", "Low", "Moderate", "High", "Very high", "Full"
	];
	size_t       menuLevel;
	const size_t menuLevels = 2;

	this() {
		
	}

	void Reset() {
		selectedBelieverLevel = 0;
		menuLevel             = 0;
	}

	void HandleKeyPress(SDL_Scancode key) {
		switch (key) {
			case SDL_SCANCODE_DOWN: {
				if (menuLevel < menuLevels - 1) {
					++ menuLevel;
				}
				break;
			}
			case SDL_SCANCODE_UP: {
				if (menuLevel > 0) {
					-- menuLevel;
				}
				break;
			}
			case SDL_SCANCODE_RIGHT: {
				switch (menuLevel) {
					case 0: { // believer level
						if (selectedBelieverLevel < believerLevels.length - 1) {
							++ selectedBelieverLevel;
						}
						break;
					}
					default: break;
				}
				break;
			}
			case SDL_SCANCODE_LEFT: {
				switch (menuLevel) {
					case 0: { // believer level
						if (selectedBelieverLevel > 0) {
							-- selectedBelieverLevel;
						}
						break;
					}
					default: break;
				}
				break;
			}
			case SDL_SCANCODE_SPACE: {
				switch (menuLevel) {
					case 0: break;
					case 1: {
						int[string] believerChances = [
							"None":      -1,
							"Very low":  12,
							"Low":       25,
							"Moderate":  50,
							"High":      62,
							"Very high": 75,
							"Full":      100
						];
						int believerChance = believerChances[
							believerLevels[selectedBelieverLevel]
						];
					
						auto app    = App.Instance();
						auto game   = Game.Instance();
						auto screen = app.screen;

						screen.Clear(Colour.Black);
						screen.WriteStringCentered(
							screen.GetSize().y / 2, "Generating world"
						);
						screen.Render();

						SDL_RenderPresent(VideoComponents.Instance().renderer);

						app.state = AppState.InGame;
						game.GenerateWorld(believerChance);
						break;
					}
					default: assert(0);
				}
				break;
			}
			default: break;
		}
	}

	void Render() {
		auto screen = App.Instance().screen;

		screen.Clear(' ');

		screen.WriteStringCentered(1, "World Options", Colour.BrightWhite);

		// believer level
		{
			screen.WriteStringCentered(3, "Believer levels");
			
			size_t optionsLength;
			foreach (ref level ; believerLevels) {
				optionsLength += level.length + 1;
			}

			Vec2!size_t pos = Vec2!size_t(
				(screen.GetSize().x / 2) - (optionsLength / 2), 4
			);

			foreach (i, ref level ; believerLevels) {
				ubyte colour = Colour.Black;

				if (i == selectedBelieverLevel) {
					colour = menuLevel == 0? Colour.Blue : Colour.Green;
				}

				screen.WriteString(pos, level, Colour.White, colour);

				pos.x += level.length + 1;
			}
		}

		// confirm button
		{
			ubyte colour = menuLevel == 1? Colour.Blue : Colour.Black;
			screen.WriteStringCentered(6, "Confirm", Colour.White, colour);
		}
	}
}
