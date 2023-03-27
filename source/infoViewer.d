import std.array;
import std.format;
import std.algorithm;
import bindbc.sdl;
import app;
import game;
import level;
import types;
import textScreen;

static Vec2!size_t cursor;

Menu CreateMenu() {
	Menu ret;

	ret.reset          = &Reset;
	ret.handleKeyPress = &HandleKeyPress;
	ret.handleInput    = &HandleInput;
	ret.render         = &Render;

	return ret;
}

void Reset() {
	auto game   = Game.Instance();
	auto screen = App.Instance().screen;

	cursor = Vec2!size_t(screen.GetSize().x / 2, screen.GetSize().y / 2);
	
	cursor.x += game.camera.x;
	cursor.y += game.camera.y;
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

void HandleInput(const ubyte* keyState) {
	auto game   = Game.Instance();
	auto world  = game.level;
	auto screen = App.Instance().screen;

	if (keyState[SDL_SCANCODE_W]) {
		if (cursor.y > 0) {
			-- cursor.y;

			-- game.camera.y;
			game.camera.y = max(0, game.camera.y);
		}
	}
	if (keyState[SDL_SCANCODE_S]) {
		if (cursor.y < world.GetSize().y - 1) {
			++ cursor.y;

			if (cursor.y >= screen.GetSize().y / 2) {
				++ game.camera.y;
			}
		}
	}
	if (keyState[SDL_SCANCODE_A]) {
		if (cursor.x > 0) {
			-- cursor.x;

			-- game.camera.x;
			game.camera.x = max(0, game.camera.x);
		}
	}
	if (keyState[SDL_SCANCODE_D]) {
		if (cursor.x < world.GetSize().x - 1) {
			++ cursor.x;

			if (cursor.x >= screen.GetSize().x / 2) {
				++ game.camera.x;
			}
		}
	}
}

void Render() {
	auto app    = App.Instance();
	auto game   = Game.Instance();
	auto world  = game.level;
	auto screen = app.screen;

	if ((app.ticks / (1000 / 120)) % 2 == 0) {
		Vec2!size_t pos = cursor;

		if (cursor.x >= screen.GetSize().x / 2) {
			pos.x = cursor.x - game.camera.x;
		}

		if (cursor.y >= screen.GetSize().y / 2) {
			pos.y = cursor.y - game.camera.y;
		}

		pos.y += 3;
	
		screen.SetCharacter(pos, 'X', Colour.BrightYellow);
	}

	Rect!size_t infoBox = Rect!size_t(0, 4, 30, 30);

	infoBox.x = screen.GetSize().x - infoBox.w - 1;

	screen.FillRect(infoBox, ' ');
	screen.DrawBox(infoBox);

	auto tile = world.GetTile(cursor);

	string[] lines = [
		format("Type: %s", tile.type)
	];

	switch (tile.type) {
		case TileType.House: {
			lines ~= [
				"",
				"Residents:",
			];

			foreach (ref person ; tile.meta.house.residents) {
				lines ~= person.name.join(" ");
			}
			break;
		}
		case TileType.Church: {
			auto priest = tile.meta.church.priest;

			if (priest is null) {
				lines ~= format("Priest: %s", priest.name.join(" "));
			}
			else {
				lines ~= "No priest";
			}
			break;
		}
		default: break;
	}

	screen.WriteStringLines(Vec2!size_t(infoBox.x + 1, infoBox.y + 1), lines);
}
