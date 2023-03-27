import std.format;
import std.algorithm;
import bindbc.sdl;
import app;
import game;
import level;
import types;
import textScreen;

static Town*[] towns;
static size_t  selected;

Menu CreateMenu() {
	Menu ret;

	ret.handleKeyPress = &HandleKeyPress;
	ret.render         = &Render;

	return ret;
}

void LoadTowns() {
	auto level = Game.Instance().level;

	foreach (ref town ; level.towns) {
		towns ~= &town;
	}
}

void ViewOnTown() {
	auto      town      = towns[selected];
	auto      screen    = App.Instance().screen;
	auto      game      = Game.Instance();
	auto      levelSize = game.level.GetSize();

	game.camera.x = town.pos.CastTo!long().x - (screen.GetSize().x / 2);
	game.camera.y = town.pos.CastTo!long().y - (screen.GetSize().y / 2);

	game.camera.x = max(0, game.camera.x);
	game.camera.y = max(0, game.camera.y);
}

void HandleKeyPress(SDL_Scancode key) {
	switch (key) {
		case SDL_SCANCODE_UP: {
			if (selected > 0) {
				-- selected;
				ViewOnTown();
			}
			break;
		}
		case SDL_SCANCODE_DOWN: {
			if (selected < towns.length - 1) {
				++ selected;
				ViewOnTown();
			}
			break;
		}
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
	auto thisTown   = towns[selected];
	
	Rect!size_t townsList = Rect!size_t(1, 4, 20, 10);
	screen.FillRect(townsList, ' ', Colour.White, Colour.Black);
	screen.DrawBox(townsList, Colour.White, Colour.Black);

	foreach (i, ref town ; towns) {
		string text = town.name;

		if (i == selected) {
			text = "> " ~ text;
		}

		screen.WriteString(Vec2!size_t(2, 5 + i), text);
	}

	Rect!size_t townInfo = Rect!size_t(screenSize.x - 51, 4, 50, 20);

	screen.FillRect(townInfo, ' ', Colour.White, Colour.Black);
	screen.DrawBox(townInfo, Colour.White, Colour.Black);

	string[] townInfoLines = [
		format("Buildings: %d", thisTown.houses + thisTown.churches),
		format("Houses: %d", thisTown.houses),
		format("Churches: %d", thisTown.churches)
	];

	screen.WriteStringLines(
		Vec2!size_t(townInfo.x + 1, townInfo.y + 1), townInfoLines
	);
}
