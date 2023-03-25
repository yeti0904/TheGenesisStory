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
				"%s has passed away from %s at the age of %d", name, cause, age
			)
		);
	}

	void ReportSurvival(string name, string disease) {
		Game.Instance().Report(format("%s has recovered from %s", name, disease));
	}

	void UpdatePerson() {
		auto world = Game.Instance().level;

		auto person = &world.people[personIt];

		++ person.age;

		if (person.age / 360 >= uniform(75, 120)) {
			ReportDeath(person.name.join(" "), "old age", person.age);

			world.RemoveReferences(person);
		
			world.people = world.people.remove(personIt);
			return;
		}

		if (person.plagued) {
			if (uniform(0, 50) == 25) {
				// choose whether this person will live or die
				if (uniform!"[]"(0, 4) == 0) {
					person.plagued = false;
					ReportSurvival(person.name.join(" "), "plague");
				}
				else {
					ReportDeath(person.name.join(" "), "plague", person.age);
					
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
