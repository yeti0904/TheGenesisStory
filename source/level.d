import std.random;
import types;
import textScreen;
import app;

enum TileType {
	Grass,
	Water,
	Flower,
	House
}

struct Tile {
	TileType type;
}

class Level {
	Tile[][] tiles;

	this() {
		
	}

	void SetSize(Vec2!size_t size) {
		tiles = new Tile[][](size.y, size.x);
	}

	Vec2!size_t[] GetSurroundingTiles(Vec2!size_t pos) {
		Vec2!size_t[] ret;
	
		if (pos.x > 0) {
			ret ~= Vec2!size_t(pos.x - 1, pos.y);
		}
		if (pos.y > 0) {
			ret ~= Vec2!size_t(pos.x, pos.y - 1);
		}
		if (pos.x < tiles[0].length - 1) {
			ret ~= Vec2!size_t(pos.x + 1, pos.y);
		}
		if (pos.y < tiles.length - 1) {
			ret ~= Vec2!size_t(pos.x, pos.y + 1);
		}

		if ((pos.x > 0) && (pos.y > 0)) {
			ret ~= Vec2!size_t(pos.x - 1, pos.y - 1);
		}
		if ((pos.x > 0) && (pos.y < tiles.length - 1)) {
			ret ~= Vec2!size_t(pos.x - 1, pos.y + 1);
		}
		if ((pos.x < tiles[0].length - 1) && (pos.y > 0)) {
			ret ~= Vec2!size_t(pos.x + 1, pos.y - 1);
		}
		if ((pos.x < tiles[0].length - 1) && (pos.y < tiles.length - 1)) {
			ret ~= Vec2!size_t(pos.x + 1, pos.y + 1);
		}

		return ret;
	}

	void Generate() {
		Vec2!long[] waterPositions;

		for (size_t i = 0; i < 5; ++i) {
			waterPositions ~= Vec2!long(
				uniform(0, tiles[0].length),
				uniform(0, tiles.length)
			);
		}
		
		foreach (y, ref line ; tiles) {
			foreach (x, ref tile ; line) {
				Vec2!long pos = Vec2!long(x, y);

				foreach (ref water ; waterPositions) {
					size_t distance = pos.DistanceTo(water);
				
					if (distance <= uniform(5, 40)) {
						tiles[y][x] = Tile(TileType.Water);
						break;
					}
					else {
						bool nearLand = false;

						auto surrounding = GetSurroundingTiles(
							Vec2!size_t(pos.x, pos.y)
						);
						foreach (ref tile2 ; surrounding) {
							if (tiles[tile2.y][tile2.x].type != TileType.Water) {
								nearLand = true;
								break;
							}
						}

						if (!nearLand) {
							tiles[y][x] = Tile(TileType.Water);
							break;
						}
					
						if (uniform(0, 100) == 15) {
							tiles[y][x] = Tile(TileType.Flower);
						}
						else {
							tiles[y][x] = Tile(TileType.Grass);
						}
					}
				}
			}
		}
	}

	void Render(Vec2!long offset) {
		auto screen = App.Instance().screen;

		for (
			size_t y = offset.y;
			(y - offset.y < screen.cells.length) && (y < tiles.length);
			++ y
		) {
			for (
				size_t x = offset.x;
				(x - offset.x < screen.cells[0].length) && (x < tiles[0].length);
				++ x
			) {
				Cell cell;
				auto tile = tiles[y][x];

				switch (tile.type) {
					case TileType.Grass: {
						cell.ch      = '\'';
						cell.attr.fg = Colour.Green;
						break;
					}
					case TileType.Water: {
						cell.ch      = '~';
						cell.attr.fg = Colour.Cyan;
						cell.attr.bg = Colour.Blue;
						break;
					}
					case TileType.Flower: {
						cell.ch      = '#';
						cell.attr.fg = Colour.Green;
						break;
					}
					case TileType.House: {
						cell.ch      = '#';
						cell.attr.fg = Colour.Yellow;
						break;
					}
					default: assert(0);
				}

				screen.SetCell(Vec2!size_t(x - offset.x, y - offset.y), cell);
			}
		}
	}
}
