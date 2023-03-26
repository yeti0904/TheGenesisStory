import std.array;
import std.format;
import std.random;
import std.algorithm;
import game;
import level;

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
	}

	void ReportSurvival(string name, string disease) {
		Game.Instance().Report(format("%s has recovered from %s", name, disease));
	}

	void ReportConversion(string name, string from, string to) {
		auto game = Game.Instance();
		game.Report(format("%s has converted to %s from %s", name, from, to));
		game.worldViewer.CreateData();
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

		if ((person.role != PersonRole.Priest) && (uniform(0, 1000) == 25)) {
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
