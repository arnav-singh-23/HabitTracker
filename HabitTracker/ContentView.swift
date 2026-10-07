//
//  ContentView.swift
//  HabitTracker
//
//  Created by ARNAV SINGH on 05/10/26.
//

import SwiftUI



 
 
struct Habit : Identifiable , Codable , Equatable {
    var id = UUID()
    var name : String
    var startDate : Date
    var daysDone : Set<Date> = []
    private var calendar: Calendar { .current }
    
    var daysElapsed:Int{
        let start = calendar.startOfDay(for: startDate)
        let now = calendar.startOfDay(for: .now)
        let diff = calendar.dateComponents([.day], from: start, to: now).day ?? 0
        return max(diff+1,1)
    }
    var consistency : Double{
        let days = doneToday ? daysElapsed : daysElapsed - 1
        guard days > 0 else {return 0}
        return min(Double(daysDone.count) / Double(days), 1.0)
        
    }
    var history : Bool {daysElapsed > 1 || doneToday}
    
    var doneToday :Bool { isdone(.now) }

    mutating func toggle(_ date : Date) {
            let day = calendar.startOfDay(for: date)
            if daysDone.contains(day) {
                daysDone.remove(day)
            } else {
                daysDone.insert(day)
            }
    }
    mutating func toggleToday() { toggle(.now) }
    func isdone(_ date : Date) -> Bool{
        daysDone.contains(calendar.startOfDay(for: date))
    }
    var streak: Int {
        var count = 0
        var day = calendar.startOfDay(for: .now)
        if !isdone(day) { day = calendar.date(byAdding: .day, value: -1, to: day)! }
        while isdone(day) {
            count += 1
            day = calendar.date(byAdding: .day, value: -1, to: day)!
        }
        return count
    }
    
    
}


struct ContentView: View {
    @State private var habits : [Habit] = []
    @State private var showingadd = false
    
    private static let key = "savedHabits"

       init() {
           if let data = UserDefaults.standard.data(forKey: Self.key),
              let saved = try? JSONDecoder().decode([Habit].self, from: data) {
               _habits = State(initialValue: saved)
           }
    }
    
    
    var body: some View {
        NavigationStack{
            ScrollView{
                VStack(spacing : 20){
                    if habits.isEmpty {
                        ContentUnavailableView("No habits yet", systemImage: "checklist",
                                               description: Text("Tap + to add your first one."))
                    }
                    ForEach($habits) {$habit in
                        NavigationLink{
                            HabitView(habit: $habit){
                                habits.removeAll { $0.id == habit.id }
                            }
                          
                        }label: {
                            HabitRow(habit: habit)
                        }
                        .buttonStyle(.plain)
                    }
                }.padding()
            }
            
                .navigationTitle("HABITS")
                .toolbar{
                    ToolbarItem(placement: .topBarTrailing) {
                           Button {
                               showingadd = true
                           } label: {
                               Image(systemName: "plus")
                                   .font(.title2)
                           }
                           .tint(.blue)
                           .accessibilityLabel("Add habit")
                           
        
                    }
                }
                .sheet(isPresented: $showingadd){
                    AddHabitView { habits.append($0) }
                }}
        .onChange(of: habits) {
            if let data = try? JSONEncoder().encode(habits) {
                UserDefaults.standard.set(data, forKey: Self.key)
            }
        }
        
    }
}

struct HabitView : View {
    @Binding var habit : Habit
    var onDelete: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var showdelconfirmation = false
    @State private var pendingDelete  = false
    @State private var selectedDate = Date.now
    var body: some View {
        VStack{
            Text(habit.consistency , format: .percent.precision(.fractionLength(0)))
            Text("CONSISTENCY").foregroundStyle(.secondary)
                .font(.headline)
            
            Label("\(habit.streak) - day streak" , systemImage: "flame.fill")
                .font(.title3.bold())
                .foregroundStyle(habit.streak > 0 ? .orange : .secondary)
                 .padding(.top, 8)

            Spacer()
            
            
            
            VStack(spacing: 30){
                Text("DATE STARTED : \(habit.startDate.formatted(date: .abbreviated, time: .omitted))")
                if(habit.history){
                    Text("\(habit.daysDone.count) of \(habit.daysElapsed) days done")}

                    
                else{
                    Text(" -  of \(habit.daysElapsed) days done")
                }
                    
            }.font(.subheadline)
                .foregroundStyle(.blue)
                
            
            Button{
                habit.toggleToday()
            }label: {
                Label(habit.doneToday ? "DONE TODAY (TAP TO UNDO)" : "MARK TODAY AS DONE" ,
                      systemImage: habit.doneToday ? "checkmark.circle.fill" : "circle")
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            
            Spacer()
            
            Divider()

            DatePicker("Pick a day",
                                  selection: $selectedDate,
                                  in: habit.startDate...Date.now,
                                  displayedComponents: .date)

            Button {
                   habit.toggle(selectedDate)
             } label: {
                  Label(habit.isdone(selectedDate) ? "MARKED (TAP TO UNDO)" : "MARK THIS DAY AS DONE",
                   systemImage: habit.isdone(selectedDate) ? "checkmark.circle.fill" : "circle")
                   .frame(maxWidth: .infinity)
            }
               .buttonStyle(.bordered)
                .controlSize(.large)
                       

            Spacer()
            
        }
        .padding()
        .navigationTitle(habit.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button(role: .destructive) {
                showdelconfirmation = true
            } label: {
                Image(systemName: "trash")
            }
        }
        .confirmationDialog("DELETE THIS HABIT?", isPresented: $showdelconfirmation,titleVisibility: .visible) {
                    Button("DELETE", role: .destructive) {
                        pendingDelete = true     // just set the flag
                        dismiss()                // leave the page
                    }
                    Button("CANCEL", role: .cancel) { }
                }
                .onDisappear {
                    if pendingDelete { onDelete() }   // runs after the page is gone
                }
        
    }
}
struct HabitRow : View {
    let habit : Habit
    var body: some View {
        VStack{
            HStack{
                Text(habit.name)
                    .font(.headline)
                Spacer()
                if habit.streak > 0 {
                       Label("\(habit.streak)", systemImage: "flame.fill")
                           .font(.subheadline.bold())
                           .foregroundStyle(.orange)
                }
            }
            ProgressView(value: habit.consistency)
            
            Text("\(habit.daysDone.count) of \(habit.daysElapsed) days done")

                .font(.subheadline)
                .foregroundStyle(.secondary)
            
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
        
    }
}

struct AddHabitView : View {
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var startDate = Date.now
    var onSave : (Habit) -> Void
    var body: some View {
        NavigationStack{
            Form{
                TextField("ENTER NAME" , text: $name)
                DatePicker("START DATE" , selection: $startDate , in: ...Date.now , displayedComponents: .date)
                
            }
            .navigationTitle("ADD HABIT")
            .toolbar{
                ToolbarItem(placement: .cancellationAction){
                    Button("CANCEL"){
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("ADD HABIT") {
                        let cleanName = name.trimmingCharacters(in: .whitespaces)
                        onSave(Habit(name: cleanName, startDate: startDate))
                       dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        
    }
}


#Preview {
    ContentView()
}
