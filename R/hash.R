DEFAULT_ALPHABET =  "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890"
DEFAULT_SEPS = "cfhistuCFHISTU"
RATIO_SEPARATORS = 3.5
RATIO_GUARDS = 12

shuffle = function(string, salt) {
	salt_len = nchar(salt)
	str_len = nchar(string)
	if(salt_len < 1 | str_len < 2) return(string)

	salt_sum = 0
	salt_index = 1
	string_vec = strsplit(string, split = "")[[1]]
	salt_vec = strsplit(salt, split = "")[[1]]
	for(i_str in rev(2:str_len)) {
		## Pseudo Randomize based on salt ##
		salt_index = (salt_index - 1) %% (salt_len) + 1
		salt_int_val = ascii_val(salt_vec[salt_index])
		salt_sum = salt_sum + salt_int_val
		swap_pos = (salt_sum + salt_index + salt_int_val - 1) %% (i_str - 1) + 1

		## Swap positions ##
		temp = string_vec[swap_pos]
		string_vec[swap_pos] = string_vec[i_str]
		string_vec[i_str] = temp 
		salt_index = salt_index + 1
	}

	return(paste(string_vec, collapse = ""))
}

ascii_val = function(char) {
	if(!is.character(char)) stop("ascii_val: must be character")
	strtoi(charToRaw(char), 16)
}

encode_hex = function(hex_str, settings) {
	if(hex_str == '') stop("encode_hex: invalid hex")
	hex_idx = seq(0, nchar(hex_str) - 1, 12) 

	num_vec = c()
	for(i in hex_idx) {
		num_vec = c(
			num_vec, 
			base16_to_dec(
				paste0(
					'1',
					substr(hex_str, 
						i + 1, i + 12
					)
				)
			)
		)
	}

	encode(num_vec, settings)
}

decode = function(hash_str, settings) {
	if(hash_str == '') stop("decode: invalid hashid")

	salt = settings$salt
	alphabet = settings$alphabet
	separator = settings$separator
	guards = settings$guards

	parts = split(hash_str, guards)
	hashid = ifelse(
		2 <= length(parts) & length(parts) <= 3,
		parts[2], 
		parts[1]
	)

	if(hashid == '') return('')
	lottery = substr(hashid, 1, 1)
	hashid = substr(hashid, 2, nchar(hashid))

	hash_parts = split(hashid, separator)
	unhashed_parts = c()
	for(p in hash_parts) {
		alphabet_salt = substr(
			paste0(lottery, salt, alphabet),
			1, nchar(alphabet)
		)
		alphabet = shuffle(alphabet, alphabet_salt)
		unhashed_parts = c(unhashed_parts, unhash(p, alphabet))
	}

	rehash = tryCatch({
		encode(unhashed_parts, settings)
	}, error = function(e) {
		stop("decode: invalid hash, cannot decode")
	})
	if(!all(hash_str == rehash)) {
		stop("decode: invalid hash, cannot decode")
	}

	return(unhashed_parts)
}

decode_hex = function(hashid, settings) {
	num_vec = decode(hashid, settings) # 2-vec of big numbers in base 10

	hex_vec = sapply(num_vec, function(x) {
		x = dec_to_base16(x)
		x = substr(x, 2, nchar(x))
		x
	})

	paste(hex_vec, collapse="")
}

split = function(string, splitters) {
	string_vec = strsplit(string, split = "")[[1]]
	split_vec = strsplit(splitters, split = "")[[1]]

	word = ''
	words = c()
	for(i in 1:length(string_vec)) {
		if(string_vec[i] %in% split_vec) {
			words = c(words, word)
			word = ''
		} else {
			word = paste0(word, string_vec[i])
		}
	}
	words = c(words, word)

	return(words)
}

encode = function(int, settings) {
	if(!all(c("alphabet", "salt", "guards", "separator", "min_length") 
		%in% names(settings))) {
		stop("encode: missing some parameters in settings list")
	}
	if(any(int < 0)) {
		stop("encode: numbers must be non-negative")
	}
	if(any(int %% 1 != 0)) {
		stop("encode: numbers must be integers")
	}
	if(length(int) < 1) {
		stop("encode: Invalid length!")
	}

	alphabet = settings$alphabet
	salt = settings$salt
	guards = settings$guards
	separator = settings$separator
	min_length = settings$min_length
	alphabet_len = nchar(settings$alphabet)
	sep_len = nchar(settings$separator)

	vec_hash = sum(
		sapply(
			1:length(int), function(i) {
				int[i] %% (100 + i - 1)
			}
		)
	)
	#lottery character
	lottery = substr(alphabet, 
		(vec_hash %% alphabet_len) + 1, 
		(vec_hash %% alphabet_len) + 1
	)
	encoded = lottery

	for(i in 1:length(int)) {
		alphabet_salt = substr(
			paste0(lottery, 
				salt,
				alphabet
			),
			1, alphabet_len
		)
		alphabet = shuffle(alphabet, alphabet_salt)
		last = hash(int[i], alphabet)
		encoded = paste0(encoded, last)
		int[i] = int[i] %% (ascii_val(substr(last, 1, 1)) + (i - 1))
		encoded = paste0(
			encoded,
			substr(
				separator,
				(int[i] %% sep_len + 1), 
				(int[i] %% sep_len + 1)
			)
		)
	}

	encoded = substr(encoded, 1, nchar(encoded) - 1)
	if(nchar(encoded) <= min_length) {
		encoded = enforce_min_length(encoded, min_length, alphabet, guards, vec_hash)
	}

	return(encoded)
}

enforce_min_length = function(
	encoded,
	min_length,
	alphabet,
	guards,
	values_hash) {

	guards_len = nchar(guards)
    guards_idx = (values_hash + ascii_val(substr(encoded, 1, 1))) %% guards_len + 1
    encoded = paste0(substr(guards, guards_idx, guards_idx), encoded)

    if(nchar(encoded) < min_length) {
    	guards_idx = (values_hash + ascii_val(substr(encoded, 3, 3))) %% guards_len + 1
    	encoded = paste0(encoded, substr(guards, guards_idx, guards_idx))
    }

    split_at = nchar(alphabet) / 2 + 1
    while(nchar(encoded) < min_length) {
    	alphabet = shuffle(alphabet, alphabet)
    	encoded = paste0(
    		substr(alphabet, split_at, nchar(alphabet)),
    		encoded,
    		substr(alphabet, 1, split_at - 1)
    	)
    	excess = nchar(encoded) - min_length

    	if(excess > 0) {
    		from_index = floor(excess / 2) + 1
    		encoded = substr(encoded,
    			from_index,
    			from_index + min_length - 1
    		)
    	}
    }

    return(encoded)
}

hash = function(number, alphabet) {
	alphabet_len = nchar(alphabet)
	alphabet_vec = strsplit(alphabet, split = "")[[1]]

	hashed = c()
	while(number > 0) {
		hash_idx = (number %% alphabet_len) + 1
		hashed = c(alphabet_vec[hash_idx], hashed)
		number = floor(number / alphabet_len)
	}
	return(paste(hashed, collapse = ""))
}

unhash = function(hashed, alphabet) {
	hashed_len = nchar(hashed)
	alphabet_len = nchar(alphabet)
	alphabet_vec = strsplit(alphabet, split="")[[1]]
	hashed_vec = strsplit(hashed, split="")[[1]]

	number = 0
	for(i in 1:hashed_len) {
		position = which(alphabet_vec == hashed_vec[i]) - 1
		number = number + (position * alphabet_len ** (hashed_len - i))
	}

	return(number)
}

hashid_settings = function(
	salt,
	min_length = 0,
	alphabet = DEFAULT_ALPHABET,
	sep = DEFAULT_SEPS) {

	alphabet_vec = unique(strsplit(alphabet, split = "")[[1]])
	sep_vec = unique(strsplit(sep, split = "")[[1]])

	separator_ = paste(intersect(sep_vec, alphabet_vec), collapse = "")
	alphabet_ = paste(setdiff(alphabet_vec, sep_vec), collapse = "")

	if(nchar(separator_) + nchar(alphabet_) < 16) {
	#if(nchar(alphabet_) < 16) {
		stop("hashid_settings: Alphabet must be at least 16 unique characters.")
	}

	separator_ = shuffle(separator_, salt)
	min_separators = ceiling(nchar(alphabet_) / RATIO_SEPARATORS)

	## if needed get more separators from alphabet ##
	if(nchar(separator_) < min_separators) {
		if(min_separators == 1) min_separators = 2
		split_at = min_separators - nchar(separator_)
		separator_ = paste0(separator_, substr(alphabet_, 1, split_at))
		alphabet_ = substr(alphabet_, split_at + 1, nchar(alphabet_))
	}

	alphabet_ = shuffle(alphabet_, salt)
	num_guards = ceiling(nchar(alphabet_) / RATIO_GUARDS)

	if(nchar(alphabet_) < 3) {
		guards_ = substring(separator_, 1, num_guards)
		separator_ = substr(separator_, num_guards + 1, nchar(separator_))
	} else {
		guards_ = substring(alphabet_, 1, num_guards)
		alphabet_ = substr(alphabet_, num_guards + 1, nchar(alphabet_))
	}

	return(list(
		alphabet = alphabet_,
		salt = salt,
		guards = guards_,
		separator = separator_,
		min_length = min_length
	))
}

base16_to_dec = function(str_16) {
	str_vec = strsplit(tolower(str_16), split = "")[[1]]
	str_vec = sapply(str_vec, function(x) {
		if(x %in% as.character(0:9)) {
			as.numeric(x)
		} else if(x %in% c('a', 'b', 'c', 'd', 'e', 'f')) {
			ascii_val(x) - 87
		} else {
			stop("base16_to_dec: Invalid hex character")
		}
	})

	vec_pwrs = 16^(rev(1:length(str_vec)) - 1)

	sum(vec_pwrs * str_vec)
}

dec_to_base16 = function(dec) {
	num_vec = c()
	while(dec > 0) {
		rem = dec %% 16
		num_vec = c(rem, num_vec)
		dec = floor(dec / 16)
	}

	hex_vec = sapply(num_vec, function(x) {
		if(x < 10) {
			return(x)
		} else {
			base::letters[x - 9]
		}
	})

	paste(hex_vec, collapse="")
}
































