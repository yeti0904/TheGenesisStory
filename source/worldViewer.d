import std.format;
import bindbc.sdl;
import app;
import game;
import level;
import types;
import textScreen;

static size_t believers;
static size_t atheists;
static size_t heretics;

Menu CreateMenu() {
	Menu ret;

	ret.handleKeyPress = &HandleKeyPress;
	ret.render         = &Render;

	return ret;
}

void CreateData() {
	auto world = Game.Instance().level;

	believers = 0;
	atheists  = 0;
	heretics  = 0;

	foreach (ref person ; world.people) {
		switch (person.religion) {
			case DefaultReligion.Atheist: {
				++ atheists;
				break;
			}
			case DefaultReligion.Believer: {
				++ believers;
				break;
			}
			default: {
				++ heretics;
				break;
			}
		}
	}
}

void HandleKeyPress(SDL_Scancode key) {
	switch (key) {
		case SDL_SCANCODE_ESCAPE: {
			auto game  = Game.Instance();
			game.focus = Focus.TopMenu;
			break;
		}
		default: break;
	}
}

void Render() {
	auto screen     = App.Instance().screen;
	auto screenSize = screen.GetSize();
	auto world      = Game.Instance().level;
	
	Rect!size_t worldInfo = Rect!size_t(1, 4, 50, 30);
	screen.FillRect(worldInfo, ' ', Colour.White, Colour.Black);
	screen.DrawBox(worldInfo, Colour.White, Colour.Black);

	string[] lines = [
		format("Population: %d", world.people.length),
		format("Atheists: %d", atheists),
		format("Believers: %d", believers),
		format("Heretics: %d", heretics)
	];

	screen.WriteStringLines(Vec2!size_t(2, 5), lines);
}
