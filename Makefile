.PHONY: test test-parallel test-sequential test-clean test-ps

# Target principale per i test - usa parallel se disponibile, altrimenti esegue in sequenza
test:
	@which parallel > /dev/null 2>&1 && $(MAKE) test-parallel || $(MAKE) test-sequential

# Target per eseguire i test in parallelo (richiede GNU Parallel)
test-parallel:
	@echo "Esecuzione di tutti i test in parallelo..."
	@find tests -name "test_*.sh" | parallel --will-cite "echo '\n\033[1;33m=== Esecuzione di {} ===\033[0m'; bash '{}' > {}.log 2>&1 && echo '\033[1;32mTest {} completato\033[0m' || (echo '\033[1;31mTest {} fallito\033[0m'; cat {}.log; exit 1)"
	@find tests -name "*.log" -delete
	@echo "\n\033[1;32mTutti i test sono stati eseguiti con successo!\033[0m"

# Target per eseguire i test in sequenza
test-sequential:
	@echo "Esecuzione di tutti i test in sequenza..."
	@for test in tests/test_*.sh; do \
		echo "\n\033[1;33m=== Esecuzione di $${test} ===\033[0m"; \
		bash "$${test}" || exit 1; \
		echo "\n"; \
	done
	@echo "\033[1;32mTutti i test sono stati eseguiti con successo!\033[0m"

# Target per pulire eventuali container di test rimasti
test-clean:
	@echo "Pulizia container di test..."
	@docker ps -a | grep test-container | awk '{print $$1}' | xargs -r docker rm -f
	@echo "Pulizia completata."

# Target per vedere i container di test attivi
test-ps:
	@docker ps -a | grep test-container || echo "Nessun container di test attivo."