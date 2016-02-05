collection @teachers
attributes :id, :school_id
node :name do |t|
  [t.last_name, t.first_name].join(", ")
end
