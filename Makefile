deploy: 
	ansible-playbook ansible/test.yml -i ansible/inventory.ini

git-cache:
	git rm -rf --cached .