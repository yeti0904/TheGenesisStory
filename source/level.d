import std.random;
import types;
import textScreen;
import app;

static const string[] names = [
	"corn", "old", "marple", "stock", "knuts", "barns", "bel", "barl", "pockling",
	"tock", "harro", "drif", "tad", "man", "east", "west", "north", "south", "rose",
	"briggs", "long", "lud", "king", "rugby", "lamp", "lan"
];

static const string[] suffixes = [
	"bury", "borough", "brough", "burgh", "by", "caster", "cester", "ford", "ham",
	"mouth", "stead", "ton", "worth", "port", "gate", "field", "shire",
];

static const string[] firstNames = [
	"Ann", "Bea", "Beth", "Blaire","Claire", "Dawn", "Dee", "Elle", "Eve", "Faye",
	"Gail", "Grace", "Gwen", "Jane","Jean", "Joy", "Kate ","Kim ","Liv ","Madge ",
	"Paige ","Pearl ","Rose", "Ruth","Sue", "Tess", "Beau", "Blake", "Brock", "Cade",
	"Cale", "Chad", "Chase", "Clark", "Cole", "Drake", "Grant", "Heath", "Jack",
	"Jake", "Kent", "Kurt", "Luke", "Max", "Neil", "Rhett", "Ross", "Todd", "Trent",
	"Troy", "Vince"
];

static const string[] lastNames = [
	"Smith", "Johnson", "Williams", "Brown", "Jones", "Garcia", "Miller", "Davis",
	"Rodriguez", "Martinez", "Hernandez", "Lopez", "Gonzalez", "Wilson", "Anderson",
	"Thomas", "Taylor", "Moore", "Jackson", "Martin", "Lee", "Perez", "Thompson",
	"White", "Harris", "Sanchez", "Clark", "Ramirez", "Lewis", "Robinson", "Walker",
	"Young", "Allen", "King", "Wright", "Scott", "Torres", "Nguyen", "Hill", "Flores",
	"Green", "Adams", "Nelson", "Baker", "Hall", "Rivera", "Campbell", "Mitchell",
	"Carter", "Roberts"
];

enum TileType {
	Empty,
	Grass1,
	Grass2,
	Grass3,
	Water,
	House,
	Church
}

enum DefaultReligion {
	Atheist  = 0,
	Believer = 1,
	Other
}

enum PersonRole {
	Normal,
	Priest,
	Prophet
}

struct Person {
	string[]   name;
	int        religion;
	PersonRole role;
	Tile*      home;
	int        birthday; // in days
	bool       plagued;

	static Person Random(
		int preligion, PersonRole prole, Tile* phome, int pbirthday = 0
	) {
		Person ret;
	
		ret.name = [
			firstNames[uniform(0, firstNames.length)],
			lastNames[uniform(0, lastNames.length)]
		];
		ret.religion = preligion;
		ret.role     = prole;
		ret.home     = phome;
		ret.birthday = pbirthday;
		ret.plagued  = false;

		return ret;
	}

	string Religion() {
		switch (religion) {
			case DefaultReligion.Believer: {
				return "believer";
			}
			case DefaultReligion.Atheist: {
				return "atheist";
			}
			default: {
				return "heretic";
			}
		}
	}
}

struct House {
	Town*     parent;
	Person*[] residents;
}

struct Church {
	Town*   parent;
	Person* priest;
	int     religion;
}

union TileMeta {
	House  house;
	Church church;
}

struct Tile {
	TileType type;
	TileMeta meta;

	this(TileType ptype) {
		type = ptype;
	}

	static Tile House(Town* parent, Person*[] residents) {
		static Tile ret;

		ret.type                 = TileType.House;
		ret.meta.house.parent    = parent;
		ret.meta.house.residents = residents;

		return ret;
	}

	static Tile Church(Town* parent, Person* priest) {
		static Tile ret;

		ret.type               = TileType.Church;
		ret.meta.church.parent = parent;
		ret.meta.church.priest = priest;

		return ret;
	}
}

struct Town {
	Vec2!size_t pos;
	string      name;
	size_t      radius;
	size_t      houses;
	size_t      churches;
}

struct Lake {
	Vec2!size_t pos;
}

class Level {
	Tile[][] tiles;
	Town[]   towns;
	Lake[]   lakes;
	Person[] people;
	Tile*[]  buildings;
	int      date; // days

	this() {
		
	}

	void SetSize(Vec2!size_t size) {
		tiles = new Tile[][](size.y, size.x);
	}

	Vec2!size_t GetSize() {
		return Vec2!size_t(tiles[0].length, tiles.length);
	}

	Tile GetTile(Vec2!size_t pos) {
		return tiles[pos.y][pos.x];
	}

	void RemoveReferences(Person* person) {
		foreach (ref building ; buildings) {
			switch (building.type) {
				case TileType.House: {
					foreach (ref resident ; building.meta.house.residents) {
						if (resident == person) {
							resident = null;
							break;
						}
					}
					break;
				}
				case TileType.Church: {
					if (building.meta.church.priest == person) {
						building.meta.church.priest = null;
					}
					break;
				}
				default: assert(0);
			}
		}
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

	void Generate(int believerChance) {
		date = 100 * 360;
	
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

			foreach (ref town ; towns) {
				if (town.pos.CastTo!long().DistanceTo(townPos.CastTo!long()) <= 25) {
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
					
						switch (uniform!"[]"(1, 20)) {
							case 1: {
								tiles[y][x] = Tile(TileType.Grass1);
								break;
							}
							case 2: {
								tiles[y][x] = Tile(TileType.Grass2);
								break;
							}
							case 3: {
								tiles[y][x] = Tile(TileType.Grass3);
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
							switch (uniform(0, 30)) {
								case 0: {
									tiles[y][x] = Tile.Church(
										&town, null
									);
									++ town.churches;

									auto church = &tiles[y][x].meta.church;

									people ~= Person.Random(
										DefaultReligion.Believer,
										PersonRole.Priest,
										&tiles[y][x],
										uniform(40, 82) * 360
									);
									
									church.parent   = &town;
									church.priest   = &people[$ - 1];
									church.religion = DefaultReligion.Believer;
									break;
								}
								default: {
									tiles[y][x] = Tile.House(
										&town, []
									);
									++ town.houses;

									auto house   = &tiles[y][x].meta.house;
									house.parent = &town;

									for (size_t i = 0; i < uniform(0, 4); ++ i) {
										int chance   = uniform!"[]"(0, 100);
										int religion = DefaultReligion.Atheist;

										if (chance <= believerChance) {
											religion = DefaultReligion.Believer;
										}
									
										people ~= Person.Random(
											religion,
											PersonRole.Normal,
											&tiles[y][x],
											uniform(40, 82) * 360
										);

										house.residents ~= &people[$ - 1];
									}
									break;
								}
							}

							buildings ~= &tiles[y][x];
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
			(y - offset.y < screen.cells.length - 3) && (y < tiles.length);
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
					case TileType.Grass1: {
						cell.ch      = '\'';
						cell.attr.fg = Colour.BrightGreen;
						break;
					}
					case TileType.Grass2: {
						cell.ch      = '"';
						cell.attr.fg = Colour.Green;
						break;
					}
					case TileType.Grass3: {
						cell.ch      = '.';
						cell.attr.fg = Colour.Green;
						break;
					}
					case TileType.Water: {
						cell.ch      = '~';
						cell.attr.fg = Colour.Cyan;
						cell.attr.bg = Colour.Blue;
						break;
					}
					case TileType.House: {
						cell.ch      = '#';
						cell.attr.fg = Colour.BrightYellow;
						break;
					}
					case TileType.Church: {
						cell.ch      = '+';
						cell.attr.fg = Colour.BrightCyan;
						break;
					}
					default: assert(0);
				}

				screen.SetCell(Vec2!size_t(x - offset.x, (y - offset.y) + 3), cell);
			}
		}
	}
}
