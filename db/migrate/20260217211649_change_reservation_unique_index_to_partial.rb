class ChangeReservationUniqueIndexToPartial < ActiveRecord::Migration[7.2]
  def change
    remove_index :reservations, name: "index_reservations_on_user_and_class"
    add_index :reservations, [:user_id, :studio_class_id],
      unique: true,
      where: "status != 'cancelled'",
      name: "index_reservations_on_user_and_class"
  end
end
