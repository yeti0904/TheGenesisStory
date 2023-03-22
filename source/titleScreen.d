import std.array;
import core.stdc.stdlib;
import bindbc.sdl;
import app;
import game;
import types;
import video;
import textScreen;

static string[] titleArt = [
	"████████ ██   ██ ███████      ██████  ███████ ███    ██ ███████ ███████ ██ ███████     ███████ ████████  ██████  ██████  ██    ██ ",
	"   ██    ██   ██ ██          ██       ██      ████   ██ ██      ██      ██ ██          ██         ██    ██    ██ ██   ██  ██  ██  ",
	"   ██    ███████ █████       ██   ███ █████   ██ ██  ██ █████   ███████ ██ ███████     ███████    ██    ██    ██ ██████    ████   ",
	"   ██    ██   ██ ██          ██    ██ ██      ██  ██ ██ ██           ██ ██      ██          ██    ██    ██    ██ ██   ██    ██    ",
	"   ██    ██   ██ ███████      ██████  ███████ ██   ████ ███████ ███████ ██ ███████     ███████    ██     ██████  ██   ██    ██    "
];

class TitleScreen {
	string[] buttons;
	size_t   buttonSelection;

	this() {
		buttons = [
			"Continue",
			"Create World",
			"Exit"
		];

		foreach (ref line ; titleArt) {
			line = line.replace('█', cast(char) 0xDB);
		}
	}

	void Reset() {
		buttonSelection = 0;
	}

	void HandleKeyPress(SDL_Scancode key) {
		switch (key) {
			case SDL_SCANCODE_DOWN: {
				if (buttonSelection < buttons.length - 1) {
					++ buttonSelection;
				}
				break;
			}
			case SDL_SCANCODE_UP: {
				if (buttonSelection > 0) {
					-- buttonSelection;
				}
				break;
			}
			case SDL_SCANCODE_SPACE: {
				switch (buttons[buttonSelection]) {
					case "Continue": break;
					case "Create World": {
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
						game.GenerateWorld();
						break;
					}
					case "Exit": {
						exit(0);
					}
					default: assert(0);
				}
				break;
			}
			default: break;
		}
	}

	void Render() {
		auto screen     = App.Instance().screen;
		auto screenSize = screen.GetSize();

		screen.Clear(Colour.Black);

		screen.HorizontalLine(
			Vec2!size_t(0, 0), screenSize.x, 0xDB, Colour.Grey
		);
		screen.HorizontalLine(
			Vec2!size_t(0, screenSize.y - 1), screenSize.x, 0xDB, Colour.Grey
		);
		screen.VerticalLine(
			Vec2!size_t(0, 0), screenSize.y, 0xDB, Colour.Grey
		);
		screen.VerticalLine(
			Vec2!size_t(screenSize.x - 1, 0), screenSize.y, 0xDB, Colour.Grey
		);

		screen.HorizontalLine(
			Vec2!size_t(1, 1), screenSize.x - 2, 0xB2, Colour.Grey
		);
		screen.HorizontalLine(
			Vec2!size_t(1, screenSize.y - 2), screenSize.x - 2, 0xB2, Colour.Grey
		);
		screen.VerticalLine(
			Vec2!size_t(1, 1), screenSize.y - 2, 0xB2, Colour.Grey
		);
		screen.VerticalLine(
			Vec2!size_t(screenSize.x - 2, 1), screenSize.y - 2, 0xB2, Colour.Grey
		);

		screen.HorizontalLine(
			Vec2!size_t(2, 2), screenSize.x - 4, 0xB1, Colour.Grey
		);
		screen.HorizontalLine(
			Vec2!size_t(2, screenSize.y - 3), screenSize.x - 4, 0xB1, Colour.Grey
		);
		screen.VerticalLine(
			Vec2!size_t(2, 2), screenSize.y - 4, 0xB1, Colour.Grey
		);
		screen.VerticalLine(
			Vec2!size_t(screenSize.x - 3, 2), screenSize.y - 4, 0xB1, Colour.Grey
		);

		screen.HorizontalLine(
			Vec2!size_t(3, 3), screenSize.x - 6, 0xB0, Colour.Grey
		);
		screen.HorizontalLine(
			Vec2!size_t(3, screenSize.y - 4), screenSize.x - 6, 0xB0, Colour.Grey
		);
		screen.VerticalLine(
			Vec2!size_t(3, 3), screenSize.y - 6, 0xB0, Colour.Grey
		);
		screen.VerticalLine(
			Vec2!size_t(screenSize.x - 4, 3), screenSize.y - 6, 0xB0, Colour.Grey
		);

		screen.WriteStringLinesCentered(5, titleArt, Colour.BrightYellow);
		screen.WriteStringCentered(titleArt.length + 6, "A MESYETI Game");

		{
			size_t buttonStart = titleArt.length + 8;

			foreach (i, ref button ; buttons) {
				string text = button;
			
				if (i == buttonSelection) {
					text = "> " ~ text ~ " <";
				}
			
				screen.WriteStringCentered(buttonStart + i, text, Colour.BrightWhite);
			}
		}
	}
}
