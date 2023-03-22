import std.random;
import types;
import textScreen;
import app;

static const string[] names = [
	"corn",
	"old",
	"marple",
	"stock",
	"knuts",
	"barns",
	"bel",
	"barl",
	"pockling",
	"tock",
	"harro",
	"drif",
	"tad",
	"man",
	"east",
	"west",
	"north",
	"south",
	"rose",
	"briggs",
	"long",
	"lud",
	"king",
	"rugby",
	"lamp",
	"lan"
];

static const string[] suffixes = [
	"bury",
	"borough",
	"brough",
	"burgh",
	"by",
	"caster",
	"cester",
	"ford",
	"ham",
	"mouth",
	"stead",
	"ton",
	"worth",
	"port",
	"gate",
	"field",
	"shire",
];

enum TileType {
	Empty,
	Grass,
	Water,
	Flower,
	House
}

struct Tile {
	TileType type;
}

struct Town {
	Vec2!size_t pos;
	string      name;
	size_t      radius;
}

struct Lake {
	Vec2!size_t pos;
}

class Level {
	Tile[][] tiles;
	Town[]   towns;
	Lake[]   lakes;

	this() {
		
	}

	void SetSize(Vec2!size_t size) {
		tiles = new Tile[][](size.y, size.x);
	}

	Vec2!size_t GetSize() {
		return Vec2!size_t(tiles[0].length, tiles.length);
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
		for (size_t i = 0; i < 5; ++i) {
			lakes ~= Lake(
				Vec2!size_t(
					uniform(0, tiles[0].length),
					uniform(0, tiles.length)
				)
			);
		}

		for (size_t i = 0; i < 8; ++ i) {
			Vec2!size_t townPos;

			createTownPos:
			townPos = Vec2!size_t(
				uniform(0, tiles[0].length),
				uniform(0, tiles.length)
			);

			foreach (ref lake ; lakes) {
				auto lakePos     = lake.pos.CastTo!long();
				auto townPosLong = townPos.CastTo!long();

				if (lakePos.DistanceTo(townPosLong) <= 70) {
					goto createTownPos;
				}
			}

			string name = (
				names[uniform(0, names.length)] ~
				suffixes[uniform(0, suffixes.length)]
			);
			
			towns ~= Town(townPos, name, uniform(10, 15));
		}
		
		foreach (y, ref line ; tiles) {
			foreach (x, ref tile ; line) {
				Vec2!long pos = Vec2!long(x, y);

				foreach (ref lake ; lakes) {
					size_t distance = pos.DistanceTo(lake.pos.CastTo!long());
				
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
					
						switch (uniform(1, 20)) {
							case 5: {
								tiles[y][x] = Tile(TileType.Grass);
								break;
							}
							case 10: {
								tiles[y][x] = Tile(TileType.Flower);
								break;
							}
							default: break;
						}
					}
				}

				if (uniform(0, 5) == 1) {
					foreach (ref town ; towns) {
						size_t distance = pos.DistanceTo(town.pos.CastTo!long());

						if (distance <= town.radius) {
							tiles[y][x] = Tile(TileType.House);
							break;
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
					case TileType.Empty: break;
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
						cell.ch      = '"';
						cell.attr.fg = Colour.Green;
						break;
					}
					case TileType.House: {
						cell.ch      = '#';
						cell.attr.fg = Colour.BrightYellow;
						break;
					}
					default: assert(0);
				}

				screen.SetCell(Vec2!size_t(x - offset.x, y - offset.y), cell);
			}
		}
	}
}
