import bindbc.sdl;
import app;
import game;
import level;
import types;
import textScreen;

class TownViewer {
	Town*[] towns;
	size_t  selected;

	this() {

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
		auto screen = App.Instance().screen;
		
		Rect!size_t townsList = Rect!size_t(1, 5, 20, 10);
		screen.FillRect(townsList, ' ', Colour.White, Colour.Black);
		screen.DrawBox(townsList, Colour.White, Colour.Black);

		foreach (i, ref town ; towns) {
			string text = town.name;

			if (i == selected) {
				text = "> " ~ text;
			}

			screen.WriteString(Vec2!size_t(2, 6 + i), text);
		}
	}
}
