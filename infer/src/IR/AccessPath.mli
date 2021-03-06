(*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *)

open! IStd

(** Module for naming heap locations via the path used to access them (e.g., x.f.g, y[a].b) *)

type base = Var.t * Typ.t [@@deriving compare]

type access =
  | ArrayAccess of Typ.t * t list  (** array element type with list of access paths in index *)
  | FieldAccess of Fieldname.t  (** field name *)
[@@deriving compare, equal]

(** root var, and a list of accesses. closest to the root var is first that is, x.f.g is represented
    as (x, [f; g]) *)
and t = base * access list [@@deriving compare]

val get_typ : t -> Tenv.t -> Typ.t option
(** get the typ of the last access in the list of accesses if the list is non-empty, or the base if
    the list is empty. that is, for x.f.g, return typ(g), and for x, return typ(x) *)

val base_of_pvar : Pvar.t -> Typ.t -> base
(** create a base from a pvar *)

val of_pvar : Pvar.t -> Typ.t -> t
(** create an access path from a pvar *)

val of_id : Ident.t -> Typ.t -> t
(** create an access path from an ident *)

val of_var : Var.t -> Typ.t -> t
(** create an access path from a var *)

val of_exp :
  include_array_indexes:bool -> Exp.t -> Typ.t -> f_resolve_id:(Var.t -> t option) -> t list
(** extract the access paths that occur in [exp], resolving identifiers using [f_resolve_id]. don't
    include index expressions in array accesses if [include_array_indexes] is false *)

val of_lhs_exp :
  include_array_indexes:bool -> Exp.t -> Typ.t -> f_resolve_id:(Var.t -> t option) -> t option
(** convert [lhs_exp] to an access path, resolving identifiers using [f_resolve_id] *)

val append : t -> access list -> t
(** append new accesses to an existing access path; e.g., `append_access x.f [g, h]` produces
    `x.f.g.h` *)

val is_prefix : t -> t -> bool
(** return true if [ap1] is a prefix of [ap2]. returns true for equal access paths *)

val equal : t -> t -> bool

val equal_base : base -> base -> bool

val pp : Format.formatter -> t -> unit

val pp_base : Format.formatter -> base -> unit

val pp_access : Format.formatter -> access -> unit

module Abs : sig
  type raw = t

  type t =
    | Abstracted of raw  (** abstraction of heap reachable from an access path, e.g. x.f* *)
    | Exact of raw  (** precise representation of an access path, e.g. x.f.g *)
  [@@deriving compare]

  val equal : t -> t -> bool

  val to_footprint : int -> t -> t
  (** replace the base var with a footprint variable rooted at formal index [formal_index] *)

  val get_footprint_index_base : base -> int option
  (** return the formal index associated with the base of this access path if there is one, or None
      otherwise *)

  val with_base : base -> t -> t
  (** swap base of existing access path for [base_var] (e.g., `with_base_bvar x y.f.g` produces
      `x.f.g` *)

  val extract : t -> raw
  (** extract a raw access path from its wrapper *)

  val is_exact : t -> bool
  (** return true if [t] is an exact representation of an access path, false if it's an abstraction *)

  val leq : lhs:t -> rhs:t -> bool
  (** return true if \gamma(lhs) \subseteq \gamma(rhs) *)

  val pp : Format.formatter -> t -> unit
end

module BaseMap : PrettyPrintable.PPMap with type key = base
