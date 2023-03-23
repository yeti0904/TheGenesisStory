import std.format;
import bindbc.sdl;
import app;
import level;
import types;
import textScreen;
import townViewer;
import worldViewer;

enum Focus {
	World,
	TopMenu,
	Towns,
	WorldInfo
}

struct TopMenu {
	size_t   selected;
	string[] buttons;
}

class Game {
	Level     level;
	Vec2!long camera;
	Focus     focus;

	TopMenu     topMenu;
	TownViewer  townViewer;
	WorldViewer worldViewer;

	this() {
		topMenu.buttons = [
			"World",
			"Towns"
		];

		townViewer  = new TownViewer();
		worldViewer = new WorldViewer();
	}

	static Game Instance() {
		static Game game;

		if (!game) {
			game = new Game();
		}

		return game;
	}

	void GenerateWorld(int believerChance) {
		level = new Level();
		level.SetSize(Vec2!size_t(250, 250));

		level.Generate(believerChance);

		townViewer.LoadTowns();
	}

	void HandleKeyPress(SDL_Scancode key) {
		switch (key) {
			case SDL_SCANCODE_ESCAPE: {
				if (focus == Focus.World) {
					focus            = Focus.TopMenu;
					topMenu.selected = 0;
				}
				else {
					focus = Focus.World;
				}
				return;
			}
			default: break;
		}

		switch (focus) {
			case Focus.World: break;
			case Focus.TopMenu: {
				switch (key) {
					case SDL_SCANCODE_RIGHT: {
						if (topMenu.selected < topMenu.buttons.length - 1) {
							++ topMenu.selected;
						}
						break;
					}
					case SDL_SCANCODE_LEFT: {
						if (topMenu.selected > 0) {
							-- topMenu.selected;
						}
						break;
					}
					case SDL_SCANCODE_SPACE: {
						switch (topMenu.buttons[topMenu.selected]) {
							case "World": {
								focus = Focus.WorldInfo;
								worldViewer.CreateData();
								break;
							}
							case "Towns": {
								focus = Focus.Towns;
								townViewer.ViewOnTown();
								break;
							}
							default: assert(0);
						}
						break;
					}
					default: break;
				}
				break;
			}
			case Focus.Towns: {
				townViewer.HandleKeyPress(key);
				break;
			}
			case Focus.WorldInfo: {
				worldViewer.HandleKeyPress(key);
				break;
			}
			default: assert(0);
		}
	}

	void HandleInput(const ubyte* keyState) {
		switch (focus) {
			case Focus.World: {
				if (keyState[SDL_SCANCODE_W]) {
					if (camera.y != 0) {
						-- camera.y;
					}
				}
				if (keyState[SDL_SCANCODE_S]) {
					++ camera.y;
				}
				if (keyState[SDL_SCANCODE_A]) {
					if (camera.x != 0) {
						-- camera.x;
					}
				}
				if (keyState[SDL_SCANCODE_D]) {
					++ camera.x;
				}
				break;
			}
			default: break;
		}
	}

	void Render() {
		auto screen     = App.Instance().screen;
		auto screenSize = screen.GetSize();

		screen.Clear(' ');
	
		level.Render(camera);

		Rect!size_t infoBox = Rect!size_t(0, 0, screenSize.x, 3);

		screen.FillRect(infoBox, ' ', Colour.White, Colour.Black);
		screen.DrawBox(infoBox, Colour.White, Colour.Black);

		switch (focus) {
			case Focus.World: {
				screen.WriteString(Vec2!size_t(1, 1), "\2");
				break;
			}
			case Focus.TopMenu: {
				size_t pos = 1;
				foreach (i, ref button ; topMenu.buttons) {
					ubyte fg;
					ubyte bg;

					if (i == topMenu.selected) {
						fg = Colour.Black;
						bg = Colour.White;
					}
					else {
						fg = Colour.White;
						bg = Colour.Black;
					}

					screen.WriteString(Vec2!size_t(pos, 1), button, fg, bg);

					pos += button.length + 1;
				}
				break;
			}
			case Focus.Towns: {
				screen.WriteString(
					Vec2!size_t(1, 1),
					format(
						"Looking at town %s at %s",
						townViewer.towns[townViewer.selected].name,
						townViewer.towns[townViewer.selected].pos
					)
				);

				townViewer.Render();
				break;
			}
			case Focus.WorldInfo: {
				screen.WriteString(Vec2!size_t(1, 1), "Viewing world information");

				worldViewer.Render();
				break;
			}
			default: assert(0);
		}
	}
}
