#include <Rcpp.h>
using namespace Rcpp;

unsigned long long power(int base, unsigned int pow) {
	unsigned long long product = 1;
	if(pow == 0) return(1);
	for(unsigned int i = 0; i < pow; i++) {
		product *= base;
	}

	return(product);
}

std::string shuffleC(std::string s, std::string salt) {
	unsigned int len_salt = salt.size();
	if(len_salt == 0) return(s);

	unsigned int salt_index = 0, salt_sum = 0, salt_val, swap_idx;
	char temp;
	for(unsigned int i = s.size() - 1; i > 0; i--) {	
		salt_index = salt_index % len_salt;
		salt_val = (int) salt[salt_index];
		salt_sum += salt_val;
		swap_idx = (salt_val + salt_index + salt_sum) % i;

		temp = s[swap_idx];
		s[swap_idx] = s[i];
		s[i] = temp;
		salt_index += 1;
	}

	return(s);
}

std::string enforce_min_length(
	std::string hashid,
	int min_length,
	std::string alphabet,
	std:: string guards,
	unsigned long long vec_hash) {

	int guards_len = guards.size();
	int guards_idx = (vec_hash + (int)hashid[0]) % guards_len;
	//hashid = hashid + guards[guards_idx];
	hashid = guards[guards_idx] + hashid;

	if(hashid.size() < min_length) {
		guards_idx = (vec_hash + (int)hashid[2]) % guards_len;
		hashid = hashid + guards[guards_idx];
	}

	int split_at = alphabet.size() / 2;
	int from_index, excess;
	while(hashid.size() < min_length) {
		alphabet = shuffleC(alphabet, alphabet);
		hashid = alphabet.substr(split_at, alphabet.size() - split_at) + hashid + alphabet.substr(0, split_at);
		excess = hashid.size() - min_length;

		if(excess > 0) {
			from_index = excess / 2;
			hashid = hashid.substr(from_index, min_length);
		}
	}

	return(hashid);
}

std::string hashC(unsigned long long number, std::string alphabet) {
	unsigned int alphabet_len = alphabet.size();
	std::string hashed = "";

	unsigned int hash_idx;
	while(number > 0) {
		hash_idx = number % alphabet_len;
		hashed = alphabet[hash_idx] + hashed;
		number = number / alphabet_len;
	}

	return(hashed);
}

unsigned long long unhashC(std::string hashed, std::string alphabet) {
	unsigned long long number = 0;
	unsigned int position;
	for(unsigned int i = 0; i < hashed.size(); i++) {
		position = alphabet.find(hashed[i]);
		number += position * power(alphabet.size(), hashed.size() - i - 1);
	}
	return(number);
}

// [[Rcpp::export]]
std::string encodeC(IntegerVector num, List settings) {
	unsigned long long vec_hash = 0;
	std::string alphabet = as<std::string>(settings["alphabet"]);
	std::string salt = as<std::string>(settings["salt"]);
	std::string separators = as<std::string>(settings["separator"]);
	int min_length = settings["min_length"];

	for(int i = 0; i < num.size(); i++) {
		vec_hash += num[i] % (100 + i);
	}

	char lottery = alphabet[vec_hash % alphabet.size()];
	std::string encoded = "";
	encoded += lottery;

	std::string alphabet_salt, last;
	for(int i = 0; i < num.size(); i++) {
		alphabet_salt = (lottery + salt + alphabet).substr(0, alphabet.size());
		alphabet = shuffleC(alphabet, alphabet_salt);
		last = hashC(num[i], alphabet);

		encoded += last;
		num[i] = num[i] % ((int) (last[0]) + i);
		encoded += separators[num[i] % separators.size()];
	}

	encoded = encoded.substr(0, encoded.size() - 1);
	if(encoded.size() < min_length) {
		encoded = enforce_min_length(encoded, min_length, alphabet, settings["guards"], vec_hash);
	}

	return(encoded);
}

