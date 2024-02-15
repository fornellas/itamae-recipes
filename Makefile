LOG_LEVEL ?= info

n2p:
	itamae ssh --node-json n2p.json --log-level=$(LOG_LEVEL) --host n2p.local roles/n2p/default.rb

mmoj:
	itamae ssh --node-json mmoj.json --log-level=$(LOG_LEVEL) --host mmoj.sigstop.co.uk roles/mmoj/default.rb
