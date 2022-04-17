n2p:
	itamae ssh -j n2p.json  --host n2p.local roles/n2p/default.rb

mmoj:
	itamae ssh -j mmoj.json  --host mmoj.sigstop.co.uk roles/mmoj/default.rb

odroid:
	itamae ssh -j odroid.json  --host odroid.local roles/odroid/default.rb
