import std.math;

struct Vec2(T) {
	T x, y;

	this(T px, T py) {
		x = px;
		y = py;
	}

	double AngleTo(Vec2!T to) {
		return atan2(cast(float) (to.y - y), cast(float) (to.x - x));
	}

	Vec2!int ToIntVec() {
		return Vec2!int(cast(int) x, cast(int) y);
	}

	Vec2!float ToFloatVec() {
		return Vec2!float(cast(float) x, cast(float) y);
	}

	T DistanceTo(Vec2!T other) {
		Vec2!T distance;
		distance.x = abs(other.x - x);
		distance.y = abs(other.y - y);
		return cast(T) sqrt(
			cast(float) ((distance.x * distance.x) + (distance.y * distance.y))
		);
	}

	bool Equals(Vec2!T right) {
		return (
			(x == right.x) &&
			(y == right.y)
		);
	}
}

struct Rect(T) {
	T x, y, w, h;
}
