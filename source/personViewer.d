import std.array;
import std.format;
import std.algorithm;
import bindbc.sdl;
import app;
import game;
import level;
import types;
import textScreen;

static size_t selected;

Menu CreateMenu() {
	Menu ret;

	ret.handleKeyPress = &HandleKeyPress;
	ret.render         = &Render;

	return ret;
}

void HandleKeyPress(SDL_Scancode key) {
	switch (key) {
		case SDL_SCANCODE_ESCAPE: {
			auto game  = Game.Instance();
			game.focus = Focus.TopMenu;
			break;
		}
		case SDL_SCANCODE_UP: {
			if (selected > 0) {
				-- selected;
			}
			break;
		}
		case SDL_SCANCODE_DOWN: {
			auto world = Game.Instance().level;

			if (selected < world.people.length - 1) {
				++ selected;
			}
			break;
		}
		default: break;
	}
}

void Render() {
	auto screen     = App.Instance().screen;
	auto screenSize = screen.GetSize();
	auto world      = Game.Instance().level;
	auto people     = &world.people;
	
	Rect!size_t personList = Rect!size_t(1, 4, 20, screenSize.y - 5);
	screen.FillRect(personList, ' ');
	screen.DrawBox(personList);

	size_t   personStart = 0;
	string[] lines;

	if (selected > personList.h / 2) {
		personStart = selected - (personList.h / 2);
	}

	for (size_t i = personStart; i < people.length; ++i) {
		auto person = (*people)[i];

		lines ~= person.name.join(" ");

		if (lines.length == personList.h - 2) {
			break;
		}
	}

	foreach (i, ref line ; lines) {
		ubyte fg = Colour.White;
		ubyte bg = Colour.Black;
		
		if (personStart + i == selected) {
			swap(fg, bg);
		}

		screen.WriteString(Vec2!size_t(2, 5 + i), line, fg, bg);
	}

	Rect!size_t infoBox = Rect!size_t(22, 4, screenSize.x - 23, screenSize.y - 5);
	screen.FillRect(infoBox, ' ');
	screen.DrawBox(infoBox);

	auto person = (*people)[selected];

	int age = world.date - person.birthday;

	lines = [
		format("Name: %s", person.name.join(" ")),
		format("Age: %d years and %d months", age / 360, age % 360 / 30),
		format("Religion: %s", cast(DefaultReligion) person.religion),
		format("Role: %s", person.role)
	];

	switch (person.role) {
		case PersonRole.Normal: {
			lines ~= format("Town: %s", person.home.meta.house.parent.name);
			break;
		}
		case PersonRole.Priest: {
			lines ~= format("Town: %s", person.home.meta.church.parent.name);
			break;
		}
		default: break;
	}

	if (person.plagued) {
		lines ~= "Currently ill with the plague";
	}

	screen.WriteStringLines(Vec2!size_t(infoBox.x + 1, infoBox.y + 1), lines);
}
