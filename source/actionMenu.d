import std.format;
import std.algorithm;
import bindbc.sdl;
import app;
import game;
import level;
import types;
import textScreen;

static const string[] actions = [
	"Plague atheists",
	"Plague heretics",
	"Plague everybody"
];

static size_t actionSelection;

Menu CreateMenu() {
	Menu ret;

	ret.reset          = &Reset;
	ret.handleKeyPress = &HandleKeyPress;
	ret.render         = &Render;

	return ret;
}

void Reset() {
	actionSelection = 0;
}

void HandleKeyPress(SDL_Scancode key) {
	switch (key) {
		case SDL_SCANCODE_ESCAPE: {
			auto game = Game.Instance();
			game.focus = Focus.TopMenu;
			break;
		}
		case SDL_SCANCODE_UP: {
			if (actionSelection > 0) {
				-- actionSelection;
			}
			break;
		}
		case SDL_SCANCODE_DOWN: {
			if (actionSelection < actions.length - 1) {
				++ actionSelection;
			}
			break;
		}
		case SDL_SCANCODE_SPACE: {
			auto game  = Game.Instance();
			auto world = game.level;
		
			switch (actions[actionSelection]) {
				case "Plague atheists": {
					size_t infections = 0;
					
					foreach (ref person ; world.people) {
						if (person.religion == DefaultReligion.Atheist) {
							person.plagued = true;
							++ infections;
						}
					}

					game.Report(
						format(
							"%d people have been been infected with the plague",
							infections
						)
					);
					game.focus = Focus.World;
					break;
				}
				case "Plague heretics": {
					size_t infections = 0;
				
					foreach (ref person ; world.people) {
						if (person.religion >= DefaultReligion.Other) {
							person.plagued = true;
						}
					}

					game.Report(
						format(
							"%d people have been been infected with the plague",
							infections
						)
					);
					game.focus = Focus.World;
					break;
				}
				case "Plague everybody": {
					foreach (ref person ; world.people) {
						person.plagued = true;
					}

					game.Report(
						"The entire population has been infected with the plague"
					);
					game.focus = Focus.World;
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
	auto screen     = App.Instance().screen;
	auto screenSize = screen.GetSize();
	auto game       = Game.Instance();
	auto world      = game.level;

	auto box = Rect!size_t(1, 4, screenSize.x - 2, screenSize.y - 5);

	screen.FillRect(box, ' ');
	screen.DrawBox(box);

	Vec2!size_t pos = Vec2!size_t(box.x + 1, box.y + 1);

	foreach (i, ref button ; actions) {
		ubyte fg = Colour.White;
		ubyte bg = Colour.Black;

		if (i == actionSelection) {
			swap(fg, bg);
		}

		screen.WriteString(pos, button, fg, bg);
		++ pos.y;
	}
}
