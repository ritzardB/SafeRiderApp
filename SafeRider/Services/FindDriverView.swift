//
//  FindDriverView.swift
//  SafeRider
//
//  Created by Richard Balabarcon on 21/09/2026.
//

import SwiftUI

struct FindDriverView: View {
    
    @EnvironmentObject var dataManager: DataManager
    
    @State private var searchText = ""
    
    private var filteredDrivers: [PublicDriverListing] {
        let drivers = dataManager.publicDrivers
        
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty else {
            return drivers
        }
        
        return drivers.filter { driver in
            driver.name.localizedCaseInsensitiveContains(searchText) ||
            driver.serviceArea.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        
        NavigationStack {
            ZStack {
                SafeRiderTheme.orangeTint
                    .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    
                    searchBar
                    
                    if filteredDrivers.isEmpty {
                        emptyState
                    } else {
                        driverList
                    }
                }
                .padding()
                .navigationTitle("Find a Driver")
                .navigationBarTitleDisplayMode(.large)
            }
        }
    }
        
        // MARK: - Search Bar
        
        private var searchBar: some View {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                
                TextField(
                    "Search name or service area",
                    text: $searchText
                )
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(12)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        
        // MARK: - Driver List
        
        private var driverList: some View {
            ScrollView {
                LazyVStack(spacing: 14) {
                    ForEach(filteredDrivers) { driver in
                        DriverListingCard(driver: driver)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        
        // MARK: - Empty State
        
        private var emptyState: some View {
            VStack(spacing: 12) {
                Image(systemName: "car.side")
                    .font(.system(size: 44))
                    .foregroundStyle(.secondary)
                
                Text(
                    searchText.isEmpty
                    ? "No Public Drivers Yet"
                    : "No Drivers Found"
                )
                .font(.headline)
                
                Text(
                    searchText.isEmpty
                    ? "Publicly listed drivers within your araa will appear here."
                    : "Try another name or service area."
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    // MARK: - Driver Listing Card
    
    private struct DriverListingCard: View {
        
        let driver: PublicDriverListing
        
        var body: some View {
            HStack(spacing: 14) {
                
                driverPhoto
                
                VStack(alignment: .leading, spacing: 6) {
                    
                    Text(driver.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Label(
                        driver.serviceArea,
                        systemImage: "mappin.and.ellipse"
                    )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    
                    Label(
                        driver.vehicleType,
                        systemImage: "car.side"
                    )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                
                Spacer(minLength: 0)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        
        // MARK: - Driver Photo
        
        private var driverPhoto: some View {
            AsyncImage(url: photoURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                    
                default:
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(.gray.opacity(0.6))
                        .padding(8)
                }
            }
            .frame(width: 64, height: 64)
            .background(Color.gray.opacity(0.12))
            .clipShape(Circle())
        }
        
        private var photoURL: URL? {
            guard let urlString = driver.photoURL else {
                return nil
            }
            
            return URL(string: urlString)
        }
    }
    
    
    // MARK: - Preview
    
    #Preview {
        FindDriverView()
            .environmentObject(DataManager())
    }

