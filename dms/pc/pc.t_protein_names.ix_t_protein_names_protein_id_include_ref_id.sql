--
-- Name: t_protein_names.ix_t_protein_names_protein_id_include_ref_id; Type: INDEX; Schema: pc; Owner: d3l243
--

CREATE INDEX "t_protein_names.ix_t_protein_names_protein_id_include_ref_id" ON pc.t_protein_names USING btree (protein_id) INCLUDE (reference_id, name, description, annotation_type_id);

