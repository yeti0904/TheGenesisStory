import std.format;
import std.string;
import bindbc.sdl;
import app;
import level;
import types;
import infoViewer;
import textScreen;
import townViewer;
import eventViewer;
import worldViewer;
import personViewer;
import eventManager;
import actionMenu;

enum Focus {
	World,
	TopMenu,
	Towns,
	WorldInfo,
	People,
	QuitConfirm,
	InfoView,
	Events,
	Actions
}

struct TopMenu {
	size_t   selected;
	string[] buttons;
}

struct Event {
	int    date;
	string message;
}

class Game {
	Level        level;
	Vec2!long    camera;
	Focus        focus;
	Event[]      eventLog;
	EventManager eventManager;
	bool         newEvents;

	TopMenu      topMenu;
	TownViewer   townViewer;
	WorldViewer  worldViewer;
	PersonViewer personViewer;
	InfoViewer   infoViewer;
	EventViewer  eventViewer;
	ActionMenu   actionMenu;

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

		townViewer   = new TownViewer();
		worldViewer  = new WorldViewer();
		personViewer = new PersonViewer();
		infoViewer   = new InfoViewer();
		eventViewer  = new EventViewer();
		actionMenu   = new ActionMenu();

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
		eventLog ~= Event(level.date, report);
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
							case "People": {
								focus = Focus.People;
								break;
							}
							case "Info": {
								focus = Focus.InfoView;
								infoViewer.Reset();
								break;
							}
							case "Events": {
								focus = Focus.Events;
								break;
							}
							case "Action": {
								focus = Focus.Actions;
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
			case Focus.People: {
				personViewer.HandleKeyPress(key);
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
			case Focus.InfoView: {
				infoViewer.HandleKeyPress(key);
				break;
			}
			case Focus.Events: {
				eventViewer.HandleKeyPress(key);
				break;
			}
			case Focus.Actions: {
				actionMenu.HandleKeyPress(key);
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
			case Focus.InfoView: {
				infoViewer.HandleInput(keyState);
				break;
			}
			default: break;
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
				screen.WriteString(
					Vec2!size_t(1, 1),
					format(
						"\2 | Year %d, Month %d, Day %d",
						level.date / 360,
						level.date % 360 / 30,
						level.date % 360 % 30
					)
				);
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
			case Focus.People: {
				screen.WriteString(Vec2!size_t(1, 1), "Viewing population");
			
				personViewer.Render();
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
			case Focus.InfoView: {
				screen.WriteString(
					Vec2!size_t(1, 1),
					format("Viewing tile %s", infoViewer.cursor)
				);
				infoViewer.Render();
				break;
			}
			case Focus.Events: {
				screen.WriteString(Vec2!size_t(1, 1), "Viewing events");
				eventViewer.Render();
				break;
			}
			case Focus.Actions: {
				screen.WriteString(Vec2!size_t(1, 1), "Available actions");
				actionMenu.Render();
				break;
			}
			default: assert(0);
		}
	}
}
