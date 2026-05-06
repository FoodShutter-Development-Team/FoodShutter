//
//  SupabaseClient.swift
//  FoodShutter
//
//  Supabase client singleton configuration
//

import Foundation
import Supabase

let supabase = SupabaseClient(
    supabaseURL: URL(string: "https://hauixxhtjbhemqnxqqfb.supabase.co")!,
    supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhhdWl4eGh0amJoZW1xbnhxcWZiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM4MTc5MzcsImV4cCI6MjA4OTM5MzkzN30.9eMBbXt0654BAKXAVy4ob4ou7b9WWr9nNBJOHDzBZU8",
    options: .init(
        auth: .init(
            redirectToURL: URL(string: "foodshutter://auth-callback"),
            flowType: .pkce,
            emitLocalSessionAsInitialSession: true
        )
    )
)
