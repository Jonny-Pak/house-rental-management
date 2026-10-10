package com.rental.modules.listing.dto.response;


import java.math.BigDecimal;

public class MapListingResponse {
    private Long id;
    private String title;
    private String listingType;
    private BigDecimal rentPrice;
    private String address;
    private double latitude;
    private double longitude;

    public MapListingResponse() {}
    public MapListingResponse(Long id, String title, String listingType, BigDecimal rentPrice, String address, double latitude, double longitude) {
        this.id = id;
        this.title = title;
        this.listingType = listingType;
        this.rentPrice = rentPrice;
        this.address = address;
        this.latitude = latitude;
        this.longitude = longitude;
    }
    public Long getId() { return id; }    public void setId(Long id) { this.id = id; }
    public String getTitle() { return title; }    public void setTitle(String title) { this.title = title; }
    public String getListingType() { return listingType; }    public void setListingType(String listingType) { this.listingType = listingType; }
    public BigDecimal getRentPrice() { return rentPrice; }    public void setRentPrice(BigDecimal rentPrice) { this.rentPrice = rentPrice; }
    public String getAddress() { return address; }    public void setAddress(String address) { this.address = address; }
    public double getLatitude() { return latitude; }    public void setLatitude(double latitude) { this.latitude = latitude; }
    public double getLongitude() { return longitude; }    public void setLongitude(double longitude) { this.longitude = longitude; }

}
