import std.file;
import std.path;
import std.stdio;
import std.array;
import std.string;
import std.algorithm;
import core.stdc.stdlib;
import bindbc.sdl;
import types;
import video;

static ubyte[] fontData = cast(ubyte[]) import("assets/font.ttf");

class TextComponents {
	TTF_Font*         font;
	SDL_Texture*[256] characters;

	static const Vec2!size_t fontSize = Vec2!size_t(9, 16);

	this() {
		auto video = VideoComponents.Instance();
		font       = null;

		auto support = loadSDLTTF();
		// TODO: check if it failed

		if (TTF_Init() == -1) {
			stderr.writefln(
				"Failed to initialise SDL_TTF: %s", fromStringz(TTF_GetError())
			);
			exit(1);
		}

		auto rw = SDL_RWFromMem(fontData.ptr, cast(int) fontData.length);
		font = TTF_OpenFontRW(rw, 1, 16);
		if (font is null) {
			stderr.writefln(
				"Failed to initialise SDL_TTF: %s", fromStringz(TTF_GetError())
			);
			exit(1);
		}

		foreach (i, ref texture ; characters) {
			size_t[] dontRender = [0, 173];
			if (dontRender.canFind(i)) {
				texture = null;
				continue;
			}
		
			auto colour = SDL_Colour(255, 255, 255, 255);
		
			SDL_Surface* textSurface = TTF_RenderText_Solid(
				font, cast(const char*) [cast(char) i, cast(char) 0], colour
			);
			
			if (textSurface is null) {
				stderr.writefln(
					"Failed to render text: %s", fromStringz(TTF_GetError())
				);
				exit(1);
			}
			
			texture = SDL_CreateTextureFromSurface(video.renderer, textSurface);
			if (texture is null) {
				stderr.writefln(
					"Failed to create texture: %s", fromStringz(TTF_GetError())
				);
				exit(1);
			}
		}
	}

	~this() {
		if (font !is null) {
			TTF_CloseFont(font);
		}
		if (TTF_WasInit()) {
			TTF_Quit();
		}
	}

	static TextComponents Instance() {
		static TextComponents instance;

		if (instance is null) {
			instance = new TextComponents();
		}

		return instance;
	}

	void DrawCharacter(
		SDL_Renderer* renderer, char ch, Vec2!int pos, SDL_Color colour
	) {
		auto video   = VideoComponents.Instance();
		auto texture = characters[ch];

		if (texture is null) {
			return;
		}

		SDL_SetTextureColorMod(texture, colour.r, colour.g, colour.b);

		SDL_Rect textRect;
		textRect.x = pos.x;
		textRect.y = pos.y;

		SDL_QueryTexture(texture, null, null, &textRect.w, &textRect.h);

		SDL_RenderCopy(video.renderer, texture, null, &textRect);

		SDL_SetTextureColorMod(texture, 255, 255, 255);
	}

	Vec2!int GetTextSize(string text) {
		if (text.empty()) {
			return Vec2!int(0, 0);
		}

		SDL_Surface* textSurface;
		SDL_Colour   colour = SDL_Color(0, 0, 0, 255);
		SDL_Rect     textRect;

		textSurface = TTF_RenderText_Solid(font, toStringz(text), colour);
		if (textSurface is null) {
			stderr.writefln(
				"TTF_RenderText_Solid returned NULL: %s", fromStringz(TTF_GetError())
			);
			exit(1);
		}
		Vec2!int ret = Vec2!int(textSurface.w, textSurface.h);

		SDL_FreeSurface(textSurface);

		return ret;
	}
}
