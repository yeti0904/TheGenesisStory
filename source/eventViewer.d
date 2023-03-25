import std.format;
import bindbc.sdl;
import app;
import game;
import level;
import types;
import textScreen;

class EventViewer {
	this() {
		
	}

	void HandleKeyPress(SDL_Scancode key) {
		switch (key) {
			case SDL_SCANCODE_ESCAPE: {
				auto game = Game.Instance();
				game.focus = Focus.TopMenu;
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

		string[] lines;

		foreach_reverse (ref event ; game.eventLog) {
			lines ~= format("%d days ago: %s", world.date - event.date, event.message);

			if (lines.length >= box.h - 2) {
				break;
			}
		}

		screen.WriteStringLines(Vec2!size_t(box.x + 1, box.y + 1), lines);
	}
}
