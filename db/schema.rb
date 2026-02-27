# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.2].define(version: 2026_02_24_120000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "action_text_rich_texts", force: :cascade do |t|
    t.string "name", null: false
    t.text "body"
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "categories", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.text "description"
    t.integer "sort_order", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "wellhub_category_id"
    t.index ["slug"], name: "index_categories_on_slug", unique: true
    t.index ["sort_order"], name: "index_categories_on_sort_order"
  end

  create_table "class_credits", force: :cascade do |t|
    t.bigint "user_package_id", null: false
    t.datetime "used_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_package_id"], name: "index_class_credits_on_user_package_id"
  end

  create_table "class_templates", force: :cascade do |t|
    t.bigint "category_id", null: false
    t.string "name", null: false
    t.string "style"
    t.string "level", default: "all_levels", null: false
    t.text "description"
    t.integer "default_duration", default: 60, null: false
    t.integer "default_capacity", default: 20, null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "day_of_week"
    t.time "default_start_time"
    t.bigint "teacher_id"
    t.string "wellhub_class_id"
    t.index ["active"], name: "index_class_templates_on_active"
    t.index ["category_id"], name: "index_class_templates_on_category_id"
    t.index ["teacher_id"], name: "index_class_templates_on_teacher_id"
    t.index ["wellhub_class_id"], name: "index_class_templates_on_wellhub_class_id", unique: true
  end

  create_table "external_checkins", force: :cascade do |t|
    t.string "user_identifier", null: false
    t.string "platform", null: false
    t.bigint "studio_class_id", null: false
    t.datetime "checked_in_at", null: false
    t.boolean "validated", default: false, null: false
    t.string "external_reference_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["platform"], name: "index_external_checkins_on_platform"
    t.index ["studio_class_id", "platform"], name: "index_external_checkins_on_studio_class_id_and_platform"
    t.index ["studio_class_id"], name: "index_external_checkins_on_studio_class_id"
  end

  create_table "order_items", force: :cascade do |t|
    t.bigint "order_id", null: false
    t.bigint "product_id", null: false
    t.integer "quantity", default: 1, null: false
    t.decimal "unit_price", precision: 10, scale: 2, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_order_items_on_order_id"
    t.index ["product_id"], name: "index_order_items_on_product_id"
  end

  create_table "orders", force: :cascade do |t|
    t.bigint "user_id"
    t.decimal "total", precision: 10, scale: 2, null: false
    t.string "status", default: "pending", null: false
    t.text "notes"
    t.string "stripe_payment_intent_id"
    t.string "payment_method", default: "cash", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["status"], name: "index_orders_on_status"
    t.index ["user_id"], name: "index_orders_on_user_id"
  end

  create_table "packages", force: :cascade do |t|
    t.string "name", null: false
    t.decimal "price", precision: 10, scale: 2, null: false
    t.integer "credit_count", null: false
    t.integer "expiration_days", null: false
    t.text "description"
    t.boolean "active", default: true, null: false
    t.integer "sort_order", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_packages_on_active"
  end

  create_table "pages", force: :cascade do |t|
    t.string "title", null: false
    t.string "slug", null: false
    t.boolean "published", default: false, null: false
    t.integer "sort_order", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["published"], name: "index_pages_on_published"
    t.index ["slug"], name: "index_pages_on_slug", unique: true
  end

  create_table "payments", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "stripe_payment_intent_id"
    t.string "stripe_checkout_session_id"
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.string "currency", default: "mxn", null: false
    t.string "status", default: "pending", null: false
    t.string "description"
    t.string "payable_type"
    t.bigint "payable_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "payment_method", default: "stripe"
    t.index ["payable_type", "payable_id"], name: "index_payments_on_payable_type_and_payable_id"
    t.index ["stripe_checkout_session_id"], name: "index_payments_on_stripe_checkout_session_id", unique: true
    t.index ["stripe_payment_intent_id"], name: "index_payments_on_stripe_payment_intent_id", unique: true
    t.index ["user_id"], name: "index_payments_on_user_id"
  end

  create_table "products", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.decimal "price", precision: 10, scale: 2, null: false
    t.integer "stock_quantity", default: 0, null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_products_on_active"
  end

  create_table "reservations", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "studio_class_id", null: false
    t.bigint "class_credit_id"
    t.string "status", default: "confirmed", null: false
    t.datetime "cancelled_at"
    t.boolean "late_cancel", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["class_credit_id"], name: "index_reservations_on_class_credit_id"
    t.index ["status"], name: "index_reservations_on_status"
    t.index ["studio_class_id"], name: "index_reservations_on_studio_class_id"
    t.index ["user_id", "studio_class_id"], name: "index_reservations_on_user_and_class", unique: true, where: "((status)::text <> 'cancelled'::text)"
    t.index ["user_id"], name: "index_reservations_on_user_id"
  end

  create_table "stripe_webhook_events", force: :cascade do |t|
    t.string "stripe_event_id", null: false
    t.string "event_type", null: false
    t.datetime "processed_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_type"], name: "index_stripe_webhook_events_on_event_type"
    t.index ["stripe_event_id"], name: "index_stripe_webhook_events_on_stripe_event_id", unique: true
  end

  create_table "studio_classes", force: :cascade do |t|
    t.bigint "class_template_id", null: false
    t.bigint "teacher_id", null: false
    t.date "date", null: false
    t.time "start_time", null: false
    t.time "end_time", null: false
    t.integer "duration", null: false
    t.integer "capacity", null: false
    t.integer "spots_remaining", null: false
    t.string "status", default: "scheduled", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "wellhub_slot_id"
    t.index ["class_template_id"], name: "index_studio_classes_on_class_template_id"
    t.index ["date", "start_time"], name: "index_studio_classes_on_date_and_start_time"
    t.index ["status"], name: "index_studio_classes_on_status"
    t.index ["teacher_id"], name: "index_studio_classes_on_teacher_id"
    t.index ["wellhub_slot_id"], name: "index_studio_classes_on_wellhub_slot_id", unique: true
  end

  create_table "studio_settings", force: :cascade do |t|
    t.string "key", null: false
    t.text "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_studio_settings_on_key", unique: true
  end

  create_table "subscription_plans", force: :cascade do |t|
    t.string "name", null: false
    t.decimal "price", precision: 10, scale: 2, null: false
    t.string "interval", default: "monthly", null: false
    t.string "stripe_price_id"
    t.text "description"
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_subscription_plans_on_active"
    t.index ["stripe_price_id"], name: "index_subscription_plans_on_stripe_price_id", unique: true
  end

  create_table "user_packages", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "package_id", null: false
    t.datetime "purchased_at", null: false
    t.datetime "expires_at", null: false
    t.integer "credits_remaining", null: false
    t.string "status", default: "active", null: false
    t.string "stripe_payment_intent_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["package_id"], name: "index_user_packages_on_package_id"
    t.index ["status"], name: "index_user_packages_on_status"
    t.index ["user_id", "expires_at"], name: "index_user_packages_on_user_id_and_expires_at"
    t.index ["user_id"], name: "index_user_packages_on_user_id"
  end

  create_table "user_subscriptions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "subscription_plan_id", null: false
    t.string "stripe_subscription_id"
    t.string "stripe_customer_id"
    t.string "status", default: "active", null: false
    t.datetime "current_period_start"
    t.datetime "current_period_end"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["stripe_subscription_id"], name: "index_user_subscriptions_on_stripe_subscription_id", unique: true
    t.index ["subscription_plan_id"], name: "index_user_subscriptions_on_subscription_plan_id"
    t.index ["user_id", "status"], name: "index_user_subscriptions_on_user_id_and_status"
    t.index ["user_id"], name: "index_user_subscriptions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.integer "role", default: 0, null: false
    t.string "phone"
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "stripe_customer_id"
    t.text "bio"
    t.text "styles_taught"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["role"], name: "index_users_on_role"
    t.index ["stripe_customer_id"], name: "index_users_on_stripe_customer_id", unique: true
  end

  create_table "waitlist_entries", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "studio_class_id", null: false
    t.integer "position", null: false
    t.datetime "joined_at", null: false
    t.datetime "promoted_at"
    t.string "status", default: "pending", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["status"], name: "index_waitlist_entries_on_status"
    t.index ["studio_class_id", "position"], name: "index_waitlist_entries_on_studio_class_id_and_position"
    t.index ["studio_class_id"], name: "index_waitlist_entries_on_studio_class_id"
    t.index ["user_id", "studio_class_id"], name: "index_waitlist_entries_on_user_and_class", unique: true
    t.index ["user_id"], name: "index_waitlist_entries_on_user_id"
  end

  create_table "wellhub_bookings", force: :cascade do |t|
    t.bigint "studio_class_id", null: false
    t.string "booking_number", null: false
    t.string "gympass_id", null: false
    t.string "status", default: "pending", null: false
    t.datetime "booked_at", null: false
    t.datetime "responded_at"
    t.datetime "cancelled_at"
    t.datetime "checked_in_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["booking_number"], name: "index_wellhub_bookings_on_booking_number", unique: true
    t.index ["gympass_id"], name: "index_wellhub_bookings_on_gympass_id"
    t.index ["studio_class_id", "gympass_id"], name: "index_wellhub_bookings_on_studio_class_id_and_gympass_id"
    t.index ["studio_class_id"], name: "index_wellhub_bookings_on_studio_class_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "class_credits", "user_packages"
  add_foreign_key "class_templates", "categories"
  add_foreign_key "class_templates", "users", column: "teacher_id"
  add_foreign_key "external_checkins", "studio_classes"
  add_foreign_key "order_items", "orders"
  add_foreign_key "order_items", "products"
  add_foreign_key "orders", "users"
  add_foreign_key "payments", "users"
  add_foreign_key "reservations", "class_credits"
  add_foreign_key "reservations", "studio_classes"
  add_foreign_key "reservations", "users"
  add_foreign_key "studio_classes", "class_templates"
  add_foreign_key "studio_classes", "users", column: "teacher_id"
  add_foreign_key "user_packages", "packages"
  add_foreign_key "user_packages", "users"
  add_foreign_key "user_subscriptions", "subscription_plans"
  add_foreign_key "user_subscriptions", "users"
  add_foreign_key "waitlist_entries", "studio_classes"
  add_foreign_key "waitlist_entries", "users"
  add_foreign_key "wellhub_bookings", "studio_classes"
end
