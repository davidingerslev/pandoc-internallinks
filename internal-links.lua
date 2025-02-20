-- This lua filter replaces internal links (e.g. links created by Obsidian to headers within the
-- same document) with working links e.g. equivalent to replacing [[#An Internal Link]] with
-- [An Internal Link](#an-internal-link) before exporting

-- replace_matches(inlines) is passed a list of pandoc elements inside an [[#internal link]]
-- or [[#internal link|link with alias]] and returns a list containing one Link element
local function replace_matches(inlines)
	local content = pandoc.List()
	local target = "#"

	for _, inline in ipairs(inlines) do
		-- Add this element to the text for the link. Do it here so that the content can
		-- be reset later if we find the alias pattern
		content:insert(inline)

		if inline.tag == "Str" then
			local alias_index = nil
			local alias_pattern = "|"

			-- If the element contains the alias pattern, then add the part before the pattern to the
			-- link target and the part afterwards to the text for the link
			alias_index = inline.text:find(alias_pattern, 1, true) -- start at char 1, plain pattern
			if alias_index then
				-- Add the part before the alias pattern to the link target
				target = target .. inline.text:lower():sub(1, alias_index - 1)
				-- The text for this link will now be the part after the alias_pattern plus
				-- all following elements, so reset it to a new link.
				content = pandoc.List()
				-- Add the part after the alias pattern to the text for the link
				content:insert(pandoc.Str(inline.text:sub(alias_index + alias_pattern:len())))
			else
				-- Add the element to the link target
				target = target .. inline.text:lower()
			end
		-- Replace spaces with hyphens
		elseif inline.tag == "Space" then
			target = target .. "-"
		end
	end

	return pandoc.Link(content, target)
end

-- Inlines(inlines) is called by pandoc to process the contents of blocks during filtering.
-- The function finds matching `[[#` and `]]` pairs on the same line and replaces their
-- innards by calling replace_matches()
function Inlines(inlines)
	local match_start_pattern = "[[#"
	local match_start_elem = nil
	local match_end_pattern = "]]"
	local match_start_index = nil

	for ii, inline in ipairs(inlines) do
		-- if inline.tag == "Str" then
		--   -- remove links identifiers
		--   inline.text = inline.text:gsub("^%^%w+", "")
		--   -- Pandoc always parse the escapes, so there is no way to tell
		--   -- ^ and \^ apart
		-- end

		-- abandon match (by resetting start pattern to nil) if there's a line break between start and end patterns
		if inline.tag == "SoftBreak" then
			match_start_elem = nil
		-- look for matches in Str elements
		elseif inline.tag == "Str" then
			-- check for start pattern if we haven't already found one
			if not match_start_elem then
				match_start_index = inline.text:find(match_start_pattern, 1, true) -- start at char 1, plain pattern
				if match_start_index then
					match_start_elem = ii
				end
			end
			-- if we have found a start pattern then check for end pattern
			if match_start_elem then
				local match_end_index = inline.text:find(match_end_pattern, 1, true) -- start at char 1, plain pattern
				if match_end_index then
					-- match found!
					local match_end_elem = ii
					local match_end_elem_text = inline.text

					-- create a list of elements before the match
					local inlines_before_match = pandoc.List()
					-- if there is at least one element before the start element then copy them into
					-- the list of elements before the match
					if match_start_elem > 1 then
						for jj = 1, match_start_elem - 1 do
							inlines_before_match:insert(inlines:at(jj))
						end
					end
					-- if match start pattern starts part-way through the element then create a new element
					-- for the part before the match and add it to the list of elements before the match
					local match_start_elem_text = inlines:at(match_start_elem).text
					if match_start_index ~= 1 then
						local str_before_match_start = pandoc.Str(match_start_elem_text:sub(1, match_start_index - 1))
						inlines_before_match:insert(str_before_match_start)
					end

					-- create a list of elements that contain the match
					local match_result = pandoc.List()
					-- if match start pattern ends part-way through the element then create a new element
					-- for the part after the match and add it to the list of elements containing the match
					-- (it is probably always true that the start pattern ends part-way through)
					if match_start_index - 1 + match_start_pattern:len() ~= match_start_elem_text:len() then
						match_result:insert(
							pandoc.Str(match_start_elem_text:sub(match_start_index + match_start_pattern:len()))
						)
					end
					-- if there is at least one element between the start and end elements then copy
					-- any elements in between into the list of elements containing the match
					if match_end_elem - match_start_elem > 1 then
						for jj = match_start_elem + 1, match_end_elem - 1 do
							match_result:insert(inlines:at(jj))
						end
					end
					-- if match end pattern ends part-way through the element then create a new element
					-- for the part before the match and add it to the list of elements containing the match
					-- (it is probably always true that the end pattern starts part-way through)
					if match_end_index ~= 1 then
						match_result:insert(pandoc.Str(match_end_elem_text:sub(1, match_end_index - 1)))
					end

					-- create a list of elements after the match
					local inlines_after_match = pandoc.List()
					-- if match end pattern ends part-way through the element then create a new element
					-- for the part after the match and add it to the list of elements after the match
					if match_end_index - 1 + match_end_pattern:len() ~= match_end_elem_text:len() then
						inlines_after_match:insert(
							pandoc.Str(match_end_elem_text:sub(match_end_index + match_end_pattern:len()))
						)
					end
					-- if there is at least one element after the match then copy any elements after it
					-- into the list of elements after the match
					if match_end_elem ~= #inlines then
						for jj = match_end_elem + 1, #inlines do
							inlines_after_match:insert(inlines:at(jj))
						end
					end

					-- return here with recursive call to this function
					return inlines_before_match
						:extend({ replace_matches(match_result) })
						:extend(Inlines(inlines_after_match))
				end
			end
		end
	end
	return inlines -- if we didn't find a match then we should return the original list
end
