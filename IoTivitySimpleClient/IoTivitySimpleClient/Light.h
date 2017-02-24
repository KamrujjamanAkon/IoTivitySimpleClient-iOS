//
//  Light.h
//  IoTivitySimpleClient
//
//  Created by Md. Kamrujjaman Akon on 1/26/17.
//
//

#ifndef Light_h
#define Light_h

class Light
{
public:

    bool m_state;
    int m_power;
    std::string m_name;

    Light() : m_state(false), m_power(0), m_name("")
    {
    }
};

#endif /* Light_h */
