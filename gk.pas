(*
**	Αυτό είναι ένα βοηθητικό πρόγραμμα το οποίο δέχεται πλήκτρα και
**	τυπώνει τον κωδικό τους. Τους κωδικούς αυτούς τους χρησιμοποιείς
**	στο κεντρικό πρόγραμμα.
*)
Program PrintKeyCodes;

(* Βιβλιοθήκες που χρειαζόμαστε να φορτωθούν *)
Uses crt;

(* Global μεταβλητές *)
Var	code : Integer;

(* Περιμένει να πατηθεί ένα πλήκτρο και επιστρέφει τον κωδικό του *)
Function GetKey : Integer;
Var	ch : Char;
Begin
	ch := ReadKey;
	if ch = #0 then (* non common key *)
		GetKey := 1000 + Ord(ReadKey)
	else
		GetKey := Ord(ch);
End;

(* Κεντρικό πρόγραμμα *)
Begin
	Repeat
		code := GetKey;
		WriteLn(code);
	(* Αν πατηθεί ESC ή Ctrl+C τότε βγαίνει *)
	Until (code = 27) or (code = 3);
End.
