import std.stdio;
import std.process;
import core.stdc.stdio : getchar;
import bindbc.sdl;
import text;
import video;
import types;

static SDL_Color[] palette;

enum Colour {
	Black        = 0,
	Red          = 1,
	Green        = 2,
	Yellow       = 3,
	Blue         = 4,
	Purple       = 5,
	Cyan         = 6,
	White        = 7,
	Grey         = 8,
	BrightRed    = 9,
	BrightGreen  = 10,
	BrightYellow = 11,
	BrightBlue   = 12,
	BrightPurple = 13,
	BrightCyan   = 14,
	BrightWhite  = 15
}

struct Attributes {
	ubyte fg      = 7;
	ubyte bg      = 0;
}

struct Cell {
	char       ch = ' ';
	Attributes attr;

	static Cell FromChar(char ch) {
		Cell       ret;
		Attributes attr;
		
		ret.attr = attr;
		ret.ch   = ch;

		return ret;
	}
}

class TextScreen {
	Cell[][]    cells;
	Vec2!size_t cursor;
	Pid         shell;

	this() {
		palette = [
			// https://gogh-co.github.io/Gogh/
			// Pro colour scheme
			
			/* 0 */ HexToColour(0x000000),
			/* 1 */ HexToColour(0x990000),
			/* 2 */ HexToColour(0x00A600),
			/* 3 */ HexToColour(0x999900),
			/* 4 */ HexToColour(0x2009DB),
			/* 5 */ HexToColour(0xB200B2),
			/* 6 */ HexToColour(0x00A6B2),
			/* 7 */ HexToColour(0xBFBFBF),
			/* 8 */ HexToColour(0x666666),
			/* 9 */ HexToColour(0xE50000),
			/* A */ HexToColour(0x00D900),
			/* B */ HexToColour(0xE5E500),
			/* C */ HexToColour(0x0000FF),
			/* D */ HexToColour(0xE500E5),
			/* E */ HexToColour(0x00E5E5),
			/* F */ HexToColour(0xE5E5E5)
		];
	}

	Vec2!size_t GetSize() {
		return Vec2!size_t(cells[0].length, cells.length);
	}

	void SetSize(Vec2!size_t size) {
		auto text     = TextComponents.Instance();
		auto video    = VideoComponents.Instance();
		auto newCells = new Cell[][](size.y, size.x);

		foreach (i, ref line ; cells) {
			foreach (j, ref cell ; line) {
				newCells[i][j] = cell;
			}
		}

		cells = newCells;

		SDL_SetWindowSize(
			video.window,
			cast(int) size.x * cast(int) TextComponents.fontSize.x,
			cast(int) size.y * cast(int) TextComponents.fontSize.y
		);
	}

	void SetCharacter(
		Vec2!size_t pos, char ch, ubyte fg = Colour.White, ubyte bg = Colour.Black
	) {
		try {	
			cells[pos.y][pos.x] = Cell(ch, Attributes(fg, bg));
		}
		catch (Throwable) {
			return;
		}
	}

	void WriteString(
		Vec2!size_t pos, string str, ubyte fg = Colour.White, ubyte bg = Colour.Black
	) {
		foreach (i, ref ch ; str) {
			SetCharacter(Vec2!size_t(pos.x + i, pos.y), ch, fg, bg);
		}
	}

	void WriteStringCentered(
		size_t yPos, string str, ubyte fg = Colour.White, ubyte bg = Colour.Black
	) {
		Vec2!size_t pos;
		pos.y = yPos;
		pos.x = (GetSize().x / 2) - (str.length / 2);

		WriteString(pos, str, fg, bg);
	}

	void WriteStringLines(
		Vec2!size_t pos, string[] strings,
		ubyte fg = Colour.White, ubyte bg = Colour.Black
	) {
		Vec2!size_t ipos = pos;

		for (size_t i = 0; i < strings.length; ++ i, ++ ipos.y) {
			WriteString(ipos, strings[i], fg, bg);
		}
	}

	void WriteStringLinesCentered(
		size_t yPos, string[] strings, ubyte fg = Colour.White,
		ubyte bg = Colour.Black,
	) {
		size_t iy = yPos;

		for (size_t i = 0; i < strings.length; ++ i, ++ iy) {
			WriteStringCentered(iy, strings[i], fg, bg);
		}
	}

	void HorizontalLine(
		Vec2!size_t start, size_t length, char ch,
		ubyte fg = Colour.White, ubyte bg = Colour.Black
	) {
		for (size_t x = start.x; x < start.x + length; ++ x) {
			SetCharacter(Vec2!size_t(x, start.y), ch, fg, bg);
		}
	}

	void VerticalLine(
		Vec2!size_t start, size_t length, char ch,
		ubyte fg = Colour.White, ubyte bg = Colour.Black
	) {
		for (size_t y = start.y; y < start.y + length; ++ y) {
			SetCharacter(Vec2!size_t(start.x, y), ch, fg, bg);
		}
	}

	void SetCell(Vec2!size_t pos, Cell cell) {
		cells[pos.y][pos.x] = cell;
	}

	void Clear(char ch, ubyte fg = Colour.White, ubyte bg = Colour.Black) {
		foreach (y, ref line ; cells) {
			foreach (x, ref cell ; line) {
				cell.ch      = ch;
				cell.attr.fg = fg;
				cell.attr.bg = bg;
			}
		}
	}

	void FillRect(Rect!size_t rect, char ch, ubyte fg, ubyte bg) {
		for (size_t i = rect.y; i < rect.y + rect.h; ++ i) {
			for (size_t j = rect.x; j < rect.x + rect.w; ++ j) {
				cells[i][j] = Cell(ch, Attributes(fg, bg));
			}
		}
	}

	void DrawBox(Rect!size_t rect, ubyte fg, ubyte bg) {
		for (size_t i = rect.y + 1; i < rect.y + rect.h - 1; ++ i) {
			Cell cell = Cell(0xB3, Attributes(fg, bg));
			
			cells[i][rect.x]              = cell;
			cells[i][rect.x + rect.w - 1] = cell;
		}

		for (size_t i = rect.x + 1; i < rect.x + rect.w - 1; ++ i) {
			Cell cell = Cell(0xC4, Attributes(fg, bg));

			cells[rect.y][i]              = cell;
			cells[rect.y + rect.h - 1][i] = cell;
		}

		cells[rect.y][rect.x]              = Cell(0xDA, Attributes(fg, bg));
		cells[rect.y + rect.h - 1][rect.x] = Cell(0xC0, Attributes(fg, bg));
		cells[rect.y][rect.x + rect.w - 1] = Cell(0xBF, Attributes(fg, bg));
		
		cells[rect.y + rect.h - 1][rect.x + rect.w - 1] = Cell(
			0xD9, Attributes(fg, bg)
		);
	}

	void Render() {
		auto text  = TextComponents.Instance();
		auto video = VideoComponents.Instance();

		foreach (i, ref line ; cells) {
			foreach (j, ch ; line) {
				auto rect = SDL_Rect(
					cast(int) j * cast(int) TextComponents.fontSize.x,
					cast(int) i * cast(int) TextComponents.fontSize.y,
					cast(int) TextComponents.fontSize.x,
					cast(int) TextComponents.fontSize.y
				);

				SDL_Color fg = palette[ch.attr.fg];
				SDL_Color bg = palette[ch.attr.bg];

				SDL_SetRenderDrawColor(video.renderer, bg.r, bg.g, bg.b, 255);
				SDL_RenderFillRect(video.renderer, &rect);

				if (ch.ch != ' ') {
					text.DrawCharacter(
						video.renderer, ch.ch, Vec2!int(rect.x, rect.y), fg
					);
				}
			}
		}
	}
}
