(*																				  
**	3D Graphics Library
**
**	Unit Gr3D
**
**	 7 Sep 98 - ndc - created (tutorial to 3Ds).
**	12 Dec 19 - ndc - translated to Free Pascal Compiler
*)

Unit gr3d;	(* 8 letters for DOS (unit = filename) *)

(* Ορισμός των εξαγώμενων ρουτινών *)
Interface

Procedure g3SetVPDist(vp_dist : Real);
Procedure g3SetVPDepth(vp_depth : Real);
Procedure g3SetVPAngles(x, z : Real);
Procedure g3CalcPoint(x, y, z : Real; VAR x2d : Real; VAR y2d : Real);
Procedure g3GetVPCoords(VAR x, y, z : Real);

Implementation
(* Η υλοποίηση του παραπάνω Interface *)

Var
	dist  : Real;	(* Απόσταση του σημείου παρατήρησης από την αρχή των αξόνων *)
	depth : Real;	(* Συντελεστής προοπτικής
						Θεωρητικά είναι η απόσταση του παρατηρητή από
						το επίπεδο προβολή (δηλαδή η οθόνη) *)
	x_angle : Real; (* Γωνία παρατηρητή με τον άξονα Χ *)
	z_angle : Real; (* Γωνία παρατηρητή με τον άξονα Ζ *)

	cosx, cosz, sinx, sinz : Real; (* Βελτιστοποίηση ταχύτητας *)

(*
**  Ορισμός της απόστασης του παρατηρητή από την αρχή των αξόνων
*)
Procedure g3SetVPDist(vp_dist : Real);
Begin
	dist := vp_dist;
End;

(*
**  Ορισμός της απόστασης του παρατηρητή από την οθόνη
*)
Procedure g3SetVPDepth(vp_depth : Real);
Begin
	depth := vp_depth;
End;

(*
**  Ορισμός των γωνιών του παρατηρητή ως προς τους άξονες (σε RAD)
**
**	z = γωνία του κέντρου -> VP με τον άξονα Ζ
**	x = γωνία του κέντρου -> VP με τον άξονα X
*)
Procedure g3SetVPAngles(x, z : Real);
Begin
	x_angle := x;
	z_angle := z;

	cosx := cos(x);
	sinx := sin(x);
	cosz := cos(z);
	sinz := sin(z);
End;

(*
**	Μετατροπή ενός 3Δ σημείου στη προβολή του στο επίπεδο (2Δ)
*)
Procedure g3CalcPoint(x, y, z : Real; VAR x2d : Real; VAR y2d : Real);
Var
	xe, ye, ze : Real;
Begin
	xe := -x * sinx + y * cosx;
	ye := -x * cosx * cosz - y * sinx * cosz + z * sinz;
	ze := -x * sinz * cosx - y * sinx * sinz - z * cosz + dist;

	x2d := depth * xe / ze;
	y2d := depth * ye / ze;
End;

(*
**	Επιστρέφει τις συντεταγμένες του παρατηρητή (view point)
*)
Procedure g3GetVPCoords(VAR x, y, z : Real);
Begin
	x := dist * sinz * cosx;
	y := dist * sinz * sinx;
	z := dist * cosz;
End;

End.
