module serialise.serialise;

import std.string;
import std.bitmanip;

enum ValueType {
	Integer   = 0x00,
	String    = 0x01,
	Structure = 0x02
}

enum Flags {
	Array = 0b00000001
}

union ValueContents {
	int    _int;
	string _string;

	this(int pint) {
		_int = pint;
	}

	this(string pstring) {
		_string = pstring;
	}
}

struct Value {
	ValueType type;
	bool      isArray;

	union {
		ValueContents   single;
		ValueContents[] array;
		Structure       structure;
	}

	this(int from) {
		type     = ValueType.Integer;
		isArray  = false;
		single   = ValueContents(from);
	}

	this(string from) {
		type     = ValueType.String;
		isArray  = false;
		single   = ValueContents(from);
	}

	this(int[] from) {
		type    = ValueType.Integer;
		isArray = true;

		foreach (ref val ; from) {
			array ~= ValueContents(val);
		}
	}

	this(string[] from) {
		type    = ValueType.String;
		isArray = true;

		foreach (ref val ; from) {
			array ~= ValueContents(val);
		}
	}

	this(Structure from) {
		type      = ValueType.Structure;
		isArray   = false;
		structure = from;
	}

	static Value Int(int from = 0) {
		return Value(from);
	}

	static Value String(string from = "") {
		return Value(from);
	}

	static Value IntArray(int[] from = []) {
		return Value(from);
	}

	static Value StringArray(string[] from = []) {
		return Value(from);
	}

	int GetInt() {
		assert(type == ValueType.Integer);
		assert(!array);

		return single._int;
	}

	string GetString() {
		assert(type == ValueType.String);
		assert(!array);

		return single._string;
	}

	int[] GetIntArray() {
		assert(type == ValueType.Integer);
		assert(array);

		int[] ret;

		foreach (ref val ; array) {
			ret ~= val._int;
		}

		return ret;
	}

	string[] GetStringArray() {
		assert(type == ValueType.String);
		assert(array);

		string[] ret;

		foreach (ref val ; array) {
			ret ~= val._string;
		}

		return ret;
	}
}

alias Structure = Value[];

class DataException : Exception {
	this(string msg, string file = __FILE__, size_t line = __LINE__) {
		super(msg, file, line);
	}
}

class DataManager {
	Structure[string] structures;

	void AddStructure(string name, Structure structure) {
		structures[name] = structure;
	}

	bool ValidStructure(string name, Structure structure) {
		Structure type = structures[name];

		if (structure.length != type.length) {
			return false;
		}

		foreach (i, ref val ; structure) {
			if (val.type != type[i].type) {
				return false;
			}
		}

		return true;
	}

	ubyte[] Serialise(Structure structure) {
		ubyte[] ret;

		ret ~= nativeToBigEndian(cast(ulong) structure.length);
		
		foreach (ref val ; structure) {
			ret ~= cast(ubyte) val.type;

			ubyte flags;

			if (val.isArray) {
				flags |= cast(ubyte) Flags.Array;
			}

			ret ~= flags;
			
			if (val.isArray) {
				ret ~= nativeToBigEndian(cast(ulong) val.array.length);
			}
		
			switch (val.type) {
				case ValueType.Integer: {
					if (val.isArray) {
						foreach (ref val2 ; val.array) {
							ret ~= nativeToBigEndian(val2._int);
						}
					}
					else {
						ret ~= nativeToBigEndian(val.single._int);
					}
					break;
				}
				case ValueType.String: {
					if (val.isArray) {
						foreach (ref val2 ; val.array) {
							ret ~= val2._string ~ 0;
						}
					}
					else {
						ret ~= val.single._string;
					}
					break;
				}
				case ValueType.Structure: {
					ret ~= Serialise(val.structure);
					break;
				}
				default: assert(0);
			}
		}

		return ret;
	}

	Structure Deserialise(ref ubyte[] data) {
		Structure ret;

		ulong length = bigEndianToNative!ulong(data[0 .. 8]);
		data         = data[8 .. $];

		while ((data.length > 0) && (ret.length < length)) {
			switch (cast(ValueType) data[0]) {
				case ValueType.Integer: {
					if (data[1] & Flags.Array) {
						ulong len = bigEndianToNative!ulong(data[2 .. 10]);

						data = data[10 .. $];
						
						Value array;
						array.type    = ValueType.Integer;
						array.isArray = true;

						for (ulong i = 0; i < len; ++i) {
							array.array ~= ValueContents(
								bigEndianToNative!int(data[0 .. 4])
							);
							data = data[4 .. $];
						}

						ret ~= array;
					}
					else {
						ret  ~= Value(bigEndianToNative!int(data[1 .. 5]));
						data  = data[5 .. $];
					}
					break;
				}
				case ValueType.String: {
					string str;

					data = data[1 .. $];

					while (data[0] > 0) {
						str  ~= data[0];
						data  = data[1 .. $];
					}

					data = data[1 .. $]; // remove null terminator

					ret ~= Value(str);
					break;
				}
				case ValueType.Structure: {
					ret ~= Value(Deserialise(data));
					break;
				}
				default: assert(0);
			}
		}

		return ret;
	}
}
