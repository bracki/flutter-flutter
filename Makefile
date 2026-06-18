export PATH := /opt/homebrew/bin:$(PATH)

run:
	open -a Simulator
	flutter run

test:
	flutter test

analyze:
	flutter analyze
