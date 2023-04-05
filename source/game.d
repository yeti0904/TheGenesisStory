import std.format;
import std.string;
import bindbc.sdl;
import app;
import level;
import types;
import eventManager;
import textScreen;

static import infoViewer;
static import townViewer;
static import eventViewer;
static import worldViewer;
static import personViewer;
static import actionMenu;

enum Focus {
	World,
	TopMenu,
	Towns,
	WorldInfo,
	People,
	QuitConfirm,
	InfoView,
	Events,
	Actions,

	Count
}

struct TopMenu {
	size_t   selected;
	string[] buttons;
}

struct Event {
	int    date;
	string message;
}

struct Menu {
	void function()             reset;
	void function(SDL_Scancode) handleKeyPress;
	void function(const ubyte*) handleInput;
	void function()             render;
}

class Game {
	Level        level;
	Vec2!long    camera;
	Focus        focus;
	Event[]      eventLog;
	EventManager eventManager;
	bool         newEvents;

	TopMenu      topMenu;

	Menu[Focus.Count] menus;

	this() {
		topMenu.buttons = [
			"World",
			"Towns",
			"People",
			"Info",
			"Events",
			"Action"
		];

		eventManager = new EventManager();

		menus[Focus.Towns]     = townViewer.CreateMenu();
		menus[Focus.WorldInfo] = worldViewer.CreateMenu();
		menus[Focus.People]    = personViewer.CreateMenu();
		menus[Focus.InfoView]  = infoViewer.CreateMenu();
		menus[Focus.Events]    = eventViewer.CreateMenu();
		menus[Focus.Actions]   = actionMenu.CreateMenu();

		focus = Focus.World;
	}

	static Game Instance() {
		static Game game;

		if (!game) {
			game = new Game();
		}

		return game;
	}

	void Report(string report) {
		eventLog  ~= Event(level.date, report);
		newEvents  = true;
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
			case SDL_SCANCODE_Q: {
				focus = Focus.QuitConfirm;
				break;
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
						Focus[string] actions = [
							"World": Focus.WorldInfo,
							"Towns": Focus.Towns,
							"People": Focus.People,
							"Info":   Focus.InfoView,
							"Events": Focus.Events,
							"Action": Focus.Actions
						];

						focus = actions[topMenu.buttons[topMenu.selected]];

						if (menus[focus].reset) {
							menus[focus].reset();
						}
					
						switch (focus) {
							case Focus.WorldInfo: {
								worldViewer.CreateData();
								break;
							}
							case Focus.Towns: {
								townViewer.ViewOnTown();
								break;
							}
							case Focus.Events: {
								newEvents = false;
								break;
							}
							default: break;
						}
						break;
					}
					default: break;
				}
				break;
			}
			case Focus.QuitConfirm: {
				switch (key) {
					case SDL_SCANCODE_Y: {
						auto app = App.Instance();

						app.state = AppState.TitleScreen;
						break;
					}
					case SDL_SCANCODE_N: {
						focus = Focus.World;
						break;
					}
					default: break;
				}
				break;
			}
			default: {
				if (menus[focus].handleKeyPress) {
					menus[focus].handleKeyPress(key);
				}
			}
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
			default: {
				if (menus[focus].handleInput) {
					menus[focus].handleInput(keyState);
				}
			}
		}
	}

	void Update() {
		auto app = App.Instance();

		if (app.ticks % (60 * 60) == 0) {
			++ level.date; // new day
		}
	
		eventManager.DoUpdate();
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
				string bar = format(
					"\2 | Year %d, Month %d, Day %d",
					level.date / 360,
					level.date % 360 / 30,
					level.date % 360 % 30
				);

				if (newEvents) {
					bar ~= "| New events";
				}
				
				screen.WriteString(Vec2!size_t(1, 1), bar);
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
			case Focus.QuitConfirm: {
				Rect!size_t box = Rect!size_t(0, 0, 30, 5);

				box.x = (screen.GetSize().x / 2) - (box.w / 2);
				box.y = (screen.GetSize().y / 2) - (box.h / 2);

				screen.FillRect(box, ' ');
				screen.DrawBox(box);

				screen.WriteString(
					Vec2!size_t(box.x + 1, box.y + 1), "Really quit? (Y/N)"
				);
				break;
			}
			default: {
				if (menus[focus].render) {
					menus[focus].render();
				}
			}
		}
	}
}
