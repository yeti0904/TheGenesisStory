import std.math;
import std.array;
import std.stdio;
import std.format;
import std.random;
import std.algorithm;
import game;
import level;

static import worldViewer;

class EventManager {
	size_t personIt;
	
	this() {
		
	}

	void ReportDeath(string name, string cause, int age) {
		Game.Instance().Report(
			format(
				"%s has passed away from %s at the age of %d", name, cause, age / 360
			)
		);
		worldViewer.CreateData();
	}

	void ReportSurvival(string name, string disease) {
		Game.Instance().Report(format("%s has recovered from %s", name, disease));
	}

	void ReportConversion(string name, string from, string to) {
		auto game = Game.Instance();
		game.Report(format("%s has converted to %s from %s", name, from, to));
		worldViewer.CreateData();
	}

	void ReportLove(string name, string other) {
		Game.Instance().Report(
			format("%s has started a relationship with %s", name, other)
		);
	}

	void ReportMarriage(string name, string other) {
		Game.Instance().Report(format("%s has married %s", name, other));
	}

	void UpdatePerson() {
		auto world = Game.Instance().level;

		auto person = &world.people[personIt];

		int age = world.date - person.birthday;

		if (age / 360 >= uniform(75, 120)) {
			ReportDeath(person.name.join(" "), "old age", age);

			world.RemoveReferences(person);
		
			world.people = world.people.remove(personIt);
			return;
		}

		if (
			(person.role != PersonRole.Priest) &&
			(person.so is null) &&
			(person.home.meta.house.residents.length > 1) &&
			(uniform(0, 100) == 25)
		) {
			auto    residents = person.home.meta.house.residents;
			Person* so;

			size_t attempts = 0;
			while (true) {
				so = residents[uniform(0, residents.length)];

				if (so.name[$ - 1] == person.name[$ - 1]) {
					// this is so families don't marry each other
					// since this isn't alabama simulator
					so = null;
					goto next;
				}

				if (abs(so.birthday - person.birthday) >= (10 * 360)) {
					// so there's no weird age gap
					so = null;
					goto next;
				}

				if (so != person) {
					break;
				}

				next:
				++ attempts;
				if (attempts >= 50) {
					so = null;
					break;
				}
			}

			if (so !is null) {
				person.so = so;
				so.so     = person;

				ReportLove(person.name.join(" "), so.name.join(" "));
			}
		}

		if ((person.so !is null) && (uniform(0, 500) == 25) && (!person.married)) {
			ReportMarriage(person.name.join(" "), person.so.name.join(" "));

			person.married    = true;
			person.so.married = true;
		}

		if ((person.role != PersonRole.Priest) && (uniform(0, 300) == 25)) {
			foreach (ref person2 ; person.home.meta.house.residents) {
				if (person == person2) {
					continue;
				}
			
				if (person.religion != person2.religion) {
					bool convert;

					if (person.religion == DefaultReligion.Believer) {
						convert = uniform(0, 4) > 0;
					}
					else {
						convert = uniform(0, 2) > 0;
					}
				
					if (convert) {
						auto old = person.Religion();

						person.religion = person2.religion;

						ReportConversion(person.name.join(" "), old, person.Religion());
					}
				}
			}
			
			if (uniform(0, 200) == 25) {
				auto old = person.Religion();
			
				person.religion = uniform(
					cast(int) DefaultReligion.Atheist, cast(int) DefaultReligion.Other
				);

				ReportConversion(person.name.join(" "), old, person.Religion());
			}
		}


		if (person.plagued) {
			if (uniform(0, 50) == 25) {
				// choose whether this person will live or die
				if (uniform!"[]"(0, 4) == 0) {
					person.plagued = false;
					ReportSurvival(person.name.join(" "), "plague");

					if (person.religion != DefaultReligion.Believer) {
						auto old = person.Religion();
					
						if (uniform(0, 4) > 0) {
							person.religion = DefaultReligion.Believer;
						}

						ReportConversion(person.name.join(" "), "believer", old);
					}
				}
				else {
					ReportDeath(person.name.join(" "), "plague", age);
					
					world.RemoveReferences(person);
					world.people = world.people.remove(personIt);
					return;
				}
			}
		}

		++ personIt;

		if (personIt >= world.people.length) {
			personIt = 0;
		}
	}

	void DoUpdate() {
		UpdatePerson();
	}
}
