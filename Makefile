FORMAT_PATHS = ./App/Slideverse ./Package.swift ./Sources ./Tests

format:
	swift format \
		--ignore-unparsable-files \
		--in-place \
		--recursive \
		$(FORMAT_PATHS)

lint:
	swift format lint \
		--strict \
		--recursive \
		$(FORMAT_PATHS)

.PHONY: format lint
