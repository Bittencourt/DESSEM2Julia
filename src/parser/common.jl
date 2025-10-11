module ParserCommon

export normalize_name, strip_comments, is_blank

"""normalize_name(fname) -> uppercase base filename without path"""
normalize_name(fname::AbstractString) = uppercase(Base.basename(String(fname)))

"""strip_comments(s; comment_chars=["#",";"]) -> String
Remove trailing comments and trim whitespace.
"""
function strip_comments(s::AbstractString; comment_chars=["#",";"])
    str = String(s)
    for ch in comment_chars
        idx = findfirst(ch, str)
        if idx !== nothing
            str = first(str, idx - 1)
        end
    end
    return strip(str)
end

"""is_blank(s) -> Bool: true if line is empty after trimming/comments"""
is_blank(s::AbstractString) = isempty(strip_comments(s))

end # module
