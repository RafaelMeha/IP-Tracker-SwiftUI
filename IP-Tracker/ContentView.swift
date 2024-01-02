import SwiftUI
import MapKit
import Combine

struct ContentView: View {
    @State private var ipAddress = ""
    @State private var locationDetails = LocationDetails()
    @State private var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 51.505, longitude: -0.09), span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5))
    @State private var locationCoordinates: [IdentifiableCoordinate] = []
    @State private var cancellables = Set<AnyCancellable>()

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                TextField("Enter IP address", text: $ipAddress)
                    .padding(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)) // Adjust the padding as needed
                    .font(.system(size: 18)) // Increase the font size
                    .frame(height: 50) // Set the desired height
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                Button("Search", action: searchIPAddress)
                    .padding(.vertical, 7)
                    .padding(.horizontal, 25)
                    .background(Color.white)
                    .foregroundColor(.black)
                    .cornerRadius(5)
            }
            .padding()
            .background(Color.blue)

            Map(coordinateRegion: $region, annotationItems: locationCoordinates) { item in
                MapAnnotation(coordinate: item.coordinate) {
                    Image(systemName: "mappin")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                        .foregroundColor(.black)
                }
            }
            .edgesIgnoringSafeArea(.all)

            if !locationDetails.ip.isEmpty {
                infoView
                    .background(Color.white)
                    .cornerRadius(10)
                    .padding()
            }
        }
    }

    var infoView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("IP Address: \(locationDetails.ip)")
            Text("Timezone: \(locationDetails.time_zone.offset)")
            Text("Location: \(locationDetails.city), \(locationDetails.country_name)")
            Text("ISP: \(locationDetails.isp)")
        }
        .padding()
    }

    func searchIPAddress() {
        guard isValidIPAddress(ipAddress) else {
            // Show some error to the user
            return
        }

        let urlString = "https://api.ipgeolocation.io/ipgeo?apiKey=YOUR_API_KEY&ip=\(ipAddress)"

        guard let url = URL(string: urlString) else { return }

        URLSession.shared.dataTaskPublisher(for: url)
            .map { $0.data }
            .decode(type: LocationDetails.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let err) = completion {
                        // Handle error
                        print(err)
                    }
                },
                receiveValue: { response in
                    self.updateUI(with: response)
                }
            )
            .store(in: &cancellables)
    }

    func updateUI(with response: LocationDetails) {
        self.locationDetails = response
        guard let lat = Double(response.latitude), let lng = Double(response.longitude) else {
            print("Error: Invalid latitude/longitude values")
            return
        }

        let newCoordinate = CLLocationCoordinate2D(latitude: lat, longitude: lng)
        locationCoordinates = [IdentifiableCoordinate(coordinate: newCoordinate)]

        let newRegion = MKCoordinateRegion(center: newCoordinate, span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02))
        self.region = newRegion
    }

    func isValidIPAddress(_ ip: String) -> Bool {
        // Implement IP validation logic here
        return true
    }
}

struct IdentifiableCoordinate: Identifiable {
    let id = UUID()
    var coordinate: CLLocationCoordinate2D
}

struct LocationDetails: Codable {
    var ip: String
    var time_zone: TimeZone
    var country_name: String
    var city: String
    var zipcode: String
    var isp: String
    var latitude: String
    var longitude: String

    init() {
        self.ip = ""
        self.time_zone = TimeZone(offset: 0.0)
        self.country_name = ""
        self.city = ""
        self.zipcode = ""
        self.isp = ""
        self.latitude = ""
        self.longitude = ""
    }

    enum CodingKeys: String, CodingKey {
        case ip
        case time_zone = "time_zone"
        case country_name = "country_name"
        case city
        case zipcode = "zipcode"
        case isp
        case latitude
        case longitude
    }
}

struct TimeZone: Codable {
    var offset: Double
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
